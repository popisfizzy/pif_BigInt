pif_BigInt/proc

	Add(pif_BigInt/Int)
		var
			// The result of addition.
			pif_BigInt/Sum = new(src) //src

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

			// Value that will carry over into the next block.
			carry = 0

			// Indicates to terminate on the next loop.
			terminate = 0

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
		WriteLength = max(srcLength, IntLength)

		/* Start the addition algorithm. */

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

			// Now we do the actual addition.

			// This essentially takes IntBlock and srcBlock, splits them in half, adds the halves
			// seperately (accounting for carry-over), and then brings them back together in the correct
			// fashion while account for what needs to be carried over to the next blocks. It's a decent
			// balance between memory and efficiency, as it uses the built-in addition operation as much
			// as possible.

			B1 = (srcBlock & 0x00FF) + (IntBlock & 0x00FF) + (carry & 0x00FF)
			B2 = ((srcBlock & 0xFF00) >> 8) + ((IntBlock & 0xFF00) >> 8) + ((carry & 0xFF00) >> 8) \
				 + ((B1 & 0xFF00) >> 8)
			carry = (B2 & 0xFF00) >> 8

			newBlock = (B1 & 0x00FF) | ((B2 & 0x00FF) << 8)
			Sum._SetBlock(i, newBlock)

			/* Accounting for rollover, and adding new blocks as needed. */

			if(terminate)
				// The terminate flag was set, so end the loop.

				if(newBlock == 0x0000)
					// If the new block is equal to zero, then it was unecessary and we remove it.
					Sum.Contract(1)

				break

			if( (i >= srcLength) && (i < WriteLength) )
				// If we still have more to go but don't have more space, add more empty blocks.
				Sum.Expand(1, 0x0000)

			else if(i == WriteLength)
				// If we're at the last block, there are a few housekeeping tasks we have to
				// do, just to make sure everything is okay.

				if(carry != 0)
					// If there is still more to carry, add one more block and mark the algorithm
					// to terminate. This is because when adding two binary integers of equal size,
					// the result is at most one bit more. Thus, in this case we can only expand
					// into the next block.
					Sum.Expand(1, 0x0000)

					WriteLength ++
					terminate = TRUE

				else if( ((newBlock & 0x8000) != 0) && (Int_pad == 0) && (src_pad == 0) )
					// If the last block looks negative, but Int and src are non-negative, then
					// we rolled over and need to add a zero block to the end to keep the BigInt
					// object positive.
					Sum.Expand(1, 0x000)

		// Flag the sign as needing recomputed.
		Sum.sign = null

		return Sum

	Increment()
		return src.Add(1)