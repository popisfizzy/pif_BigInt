pif_BigInt/proc

	Subtract(pif_BigInt/Int)
		var
			// The result of subtraction.
			pif_BigInt/Diff = new(src)

			// Metadata of the source object.
			srcLength = src.Length()

			// It's noticeably faster to do this, rather than call src.PadValue(). They both do
			// the same thing, though.
			src_pad = (src.blocks[src.blocks.len] & 0x8000) ? 0xFFFF : 0x0000 // src.PadValue()

			// Int metadata.
			IntLength
			Int_type

			Int_pad = null

			// The length of the data to write. When this is done, Sum.Length() will be less than or
			// equal to WriteLength+1, though exact block length depends on what is being added.
			WriteLength

			// Value that will carry over into the next block. It's one here, instead of zero, because
			// -x = ~x + 1.
			carry = 1

			// Indicates to terminate on the next loop.
			terminate = 0

			// Last two blocks. These are used to determine whether to contract Diff at the very end.
			LastBlock
			ntLastBlock

		/* Determine Int metadata */

		if(istype(Int))
			IntLength = Int.Length()
			Int_type = BIGINT

			Int_pad = (Int.Sign() < 1) ? 0xFFFF : 0x0000

		else if(istext(Int))
			// Not yet implemented.
			Int_type = STRING

		else if(istype(Int, /list))
			IntLength = Int:len
			Int_type = LIST

			// We'll determine Int_pad within the add loop, as it'll be easier
			// that way.

		/* else if(args.len > 1)
			IntLength = args.len
			Int_type = LIST

			Int = args.Copy() */

		else if(isnum(Int))
			IntLength = 1
			Int_type = INTEGER

			Int_pad = (Int < 0) ? 0xFFFF : 0x0000

		else
			throw EXCEPTION("Invalid or unknown data type for processing.")

		/* Determine the block length */

		// If I takes up i bytes and J takes up j bytes, then maximally I+J takes i+j bytes. To see
		// this, consider something like 0xFFFF + 0xFFFF = 0x0002 * 0xFFFF = 0xFFFF0. 0xFFFF is the
		// largest value (in the sense of binary value, without regards to sign) that can fill a 16-
		// bit field (i.e., BYOND's word length), so adding it twice is the same as multiplying by
		// two, which just shifts it over one bit.
		//
		// Consequently, if I has i blocks and J has j blocks, then I+J has at most max(i,j)+1 blocks.
		WriteLength = max(srcLength, IntLength)+1

		/* Start the subtraction algorithm. */

		for(var/i = 1, i <= WriteLength, i ++)
			var
				srcBlock = (i > srcLength) ? src_pad : src._GetBlock(i)
				IntBlock

				newBlock

				// First and second bytes of the result.
				B1
				B2

			if(i > IntLength)
				// If there is no more data from Int, pad it with the appropriate
				// value.
				IntBlock = Int_pad
			else
				switch(Int_type)
					if(BIGINT)
						IntBlock = Int._GetBlock(i)
					if(LIST)
						IntBlock = Int[IntLength - i + 1]

						if(i == IntLength)
							Int_pad = (IntBlock & 0x8000) ? 0xFFFF : 0x0000
					if(INTEGER)
						IntBlock = Int

			// We treat false values, in particular null, as 0.
			srcBlock = srcBlock || 0
			IntBlock = IntBlock || 0

			// Do some data validation.

			if(!isnum(IntBlock))
				throw EXCEPTION("Expecting numeric data to write to pif_BigInt object.")
			else if(IntBlock != round(IntBlock))
				throw EXCEPTION("Expecting integral data to write to pif_BigInt object.")

			// This is basically the same algorithm as from the Add() method, except we instead make IntBlock
			// negative first, and then perform the addition step. In two's complement, -x = ~x+1. While the
			// +1 part does not occur in the next line, it does occur after due to carry being initialized to 1.

			IntBlock = ~IntBlock
			B1 = (srcBlock & 0x00FF) + (IntBlock & 0x00FF) + (carry & 0x00FF)
			B2 = ((srcBlock & 0xFF00) >> 8) + ((IntBlock & 0xFF00) >> 8) + ((carry & 0xFF00) >> 8) \
				 + ((B1 & 0xFF00) >> 8)
			carry = (B2 & 0xFF00) >> 8

			newBlock = (B1 & 0x00FF) | ((B2 & 0x00FF) << 8)
			Diff._SetBlock(i, newBlock)

			/* Accounting for rollover, and adding new blocks as needed. */

			if(terminate)

				if(newBlock == 0x0000)
					Diff.Contract(1)

				LastBlock = newBlock
				break

			if( (i >= srcLength) && (i < WriteLength) )
				Diff.Expand(1, 0x0000)

				if(i == (WriteLength - 1))
					ntLastBlock = newBlock

			else if(i == WriteLength)

				if(carry != 0)
					Diff.Expand(1, 0x0000)

					WriteLength ++
					terminate = TRUE

					ntLastBlock = newBlock

				else
					LastBlock = newBlock

		// Due to the 'quasi-expansion' by making WriteLength one bigger than the max
		// of srcLength and IntLength, occasionally there is an unecessary block at the
		// end. This checks if there is, and contracts it if so.

		if( (LastBlock == 0xFFFF) && ((ntLastBlock & 0x8000) != 0))
			Diff.Contract(1)
		else if( (LastBlock == 0) && ((ntLastBlock & 0x8000) == 0))
			Diff.Contract(1)

		// Flag the sign as needing recomputed.
		Diff.sign = null

		return Diff

	Decrement()
		return src.Subtract(1)