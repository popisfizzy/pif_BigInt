pif_BigInt/proc

	/* Properties related to the blocks. */

	MostSignificantBlock()
		// The position of the most-significant (i.e., numerically-largest) non-zero
		// block, or 1 if all the blocks are equal to zero.

		. = Length()
		while( (. > 1) && (src._GetBlock(.) == 0) )
			. --

	MostSignificantBit()
		// Outputs the largest non-zero bit of the most significant block. 0 indicates
		// the least-significant-bit and 15 indicates the most-significant-bit.

		. = 15
		var
			msb = src._GetBlock(src.MostSignificantBlock())
			bitmask = 0x8000 // Equal to 1000 0000 0000 0000.in binary.
		while( !(bitmask & msb) )
			bitmask >>= 1
			. --

	LargestBit()
		// Outputs the value of the largest bit of the largest block. This is
		// used to help determine the sign of the block.

		return (src._GetBlock(src.Length()) & 0x8000) >> 15

	/* Methods to modify the block length */

	Trim()
		// Removes as many most-significant blocks as possible without changing the value
		// of the int. This means removing leading 0xFFFF blocks if src.Sign() == -1, and
		// removing leading 0x0000 blocks if src.Sign() != -1.

		// Number of blocks removed.
		. = 0

		var
			// We subtract 1, as there will always be at least one block left after a Trim() call,
			// so that we don't have just an empty list.
			Length = src.Length() - 1

			// Pad is the leading value we have to check for, while next_msb is the value of the
			// next block's most-significant bit. We can only delete a block if the following block
			// has a corresponding most-significant bit.
			pad = src.PadValue()
			next_msb = (pad == 0xFFFF) ? 0x8000 : 0x0000

		for(var/i = 0, i < Length, i ++)
			if( (src._GetBlock(Length-i+1) == pad) && ((src._GetBlock(Length-i) & 0x8000) == next_msb) )
				. ++
				src.blocks.len --

	Expand(amount = 1, pad = null)
		// Adds amount new blocks with value pad. If pad is not set, it will default to PadValue()

		pad = (pad != null) ? pad : src.PadValue()
		. = 0

		var/Length = src.Length()
		while(amount > 0)
			amount --
			. ++

			src.blocks.len ++
			src._SetBlock(Length + ., pad)

	Contract(amount = 1)
		// Removes the specified number of blocks.

		. = 0
		while(amount > 0)
			amount --
			. ++

			src.blocks.len --