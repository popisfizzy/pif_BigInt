pif_BigInt
	var
		/* Behavior data */
		mode

		/* BigInt data */

		// Blocks of words, arranged from least-significant to most-significant.
		list/blocks

		// A 'sign bit' that gives quick information about whether the BigInt object
		// is positive, negative, or zero. Can be useful to shortcut some things at
		// a glance.
		sign

		/* Constants */

		// These are used for data processing.
		const
			BIGINT	=	1
			LIST	=	2
			STRING	=	3

			// In the methods where values can be rational and not just integers, the
			// integer distinction doesn't matter, so we'll just use the same value for
			// them both.
			INTEGER	=	4
			NUMERIC	=	4

	New(pif_BigInt/Int)
		blocks = new

		if(istype(Int))
			// Format is something like new /pif_BigInt(pif_BigInt_Object)
			return src.Set(Int)

		else if(istext(Int))
			// Format is something like new /pif_BigInt("1000").
			// Not currently implemented.
			return src.Set(Int)

		else if(istype(Int, /list))
			// Format is something like new /pif_BigInt( list(0xFFFF, 0xFFF0) ).
			return src.Set(Int)

		else
			// Assumed that the format is something like new /pif_BigInt(0xFFFF, 0xFFF0).
			return src.Set(args)

	proc
		Set(pif_BigInt/Int)
			/*
			 * Used to directly set the values of the BigInt object.
			 */

			var
				// The length of the data being read in, and its type. IntLength relates to
				// how many blocks are being read in. Essentially metadata bout Int.
				IntLength
				Int_type

				// Used to figure out how to pad the data, if necessary. If non-negative,
				// it's padded with 0x0000. If negative, it's padded with 0xFFFF.
				Int_sign

				// The actual amount of data that will have to be processed. This is the max
				// of srcLength and IntLength.
				Length

				// Indicates that a non-zero block is present, which is used to help determine
				// the sign.
				nzBlock = 0

			/* Determine the metadata. */

			if(istype(Int))
				IntLength = Int.Length()
				Int_type = BIGINT

				Int_sign = Int.Sign()

			else if(istype(Int, /list))
				IntLength = Int:len
				Int_type = LIST

				// While we can figure out the sign directly for numeric and BigInt data types,
				// it's not as easy for list data. Instead, we'll figure it out as we're reading
				// in the data.

			else if(istext(Int))
				// Not yet implemented.
				Int_type = STRING

			else if(isnum(Int))
				// Passing a number amounts to a single block.
				IntLength = 1
				Int_type = INTEGER

				Int_sign = (Int < 0) ? -1 : 1

			else
				// Unknown data type.
				throw EXCEPTION("Invalid or unknown data type for processing.")

			/* Begin writing of new data. */

			// This method will have to be rewritten later to conform to some plans for the library, so
			// its implementation right now probably looks weird.

			Length = IntLength // max(IntLength, blocks.len)
			src.blocks.len = Length

			for(var/i = 1, i <= Length, i ++)
				var/IntBlock

				if(i > IntLength)
					// We 'pad' the data if the index is too large. If Int is non-negative, the data is
					// padded with 0x0000; if it's negative, it's padded with 0xFFFF.
					IntBlock = (Int_sign < 0) ? 0xFFFF : 0x0000
				else
					// Otherwise, grab the appropriate block.

					switch(Int_type)
						if(BIGINT)
							IntBlock = Int._GetBlock(i)
						if(LIST)
							// In a list, the blocks closer to the front are considered more significant,
							// which makes intuitive sense. E.g., something like 0xABCDEF01 would be written
							// in list form as list(0xABCD, 0xEF01), while if less-significant blocks were
							// closer to the front it would be list(0xEF01, 0xABCD).
							IntBlock = Int[IntLength - i + 1]

							if(i == IntLength)
								// This is the most significant block, so we read the most significant bit
								// to determine the data type. If this bit is zero, then the sign is non-
								// negative. It's it's one, the value is negative.
								Int_sign = ((IntBlock & 0x8000) == 0) ? 1 : -1

						if(INTEGER)
							IntBlock = Int

				// We treat false values, in particular null, as zero.
				IntBlock = IntBlock || 0

				// Data verification.

				if(!isnum(IntBlock))
					throw EXCEPTION("Expecting numeric data to write to pif_BigInt object.")
				else if(IntBlock != round(IntBlock))
					throw EXCEPTION("Expecting integral data to write to pif_BigInt object.")

				// If nzBlock already has a non-zero value, then it will just be written to nzBlock again.
				// If it is still zero, then it will see if IntBlock is non-zero, and if it is it will
				// store i in nzBlock.
				nzBlock = nzBlock || (IntBlock && i)

				// Write the data.
				src._SetBlock(i, IntBlock)

			if(nzBlock != 0)
				// If nzBlock is non-zero, then there was a non-zero block found and so the sign is
				// non-zero. We check the largest available bit. If it's non-zero, then under the two's
				// complement representation this is a negative number. If it zero, then the number
				// is positive.

				src.sign = src.LargestBit() ? -1 : 1
			else
				// If nzBlock is zero, then all blocks written were zero so the sign iz just 0.
				src.sign = 0

			return src