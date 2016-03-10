pif_BigInt/proc

	Bit(bit_pos, block_pos = null)

		if(block_pos == null)
			block_pos = round(bit_pos / 16) + 1
			bit_pos %= 16

		return (src._GetBlock(block_pos) >> bit_pos) & 0x0001

	BitsInteger(bit_pos, bit_length, block_pos = null)

		if(block_pos == null)
			block_pos = round(bit_pos / 16) + 1
			bit_pos %= 16

		if(block_pos > Length())
			return 0

		else if( ((bit_pos + bit_length) < 16) || ((block_pos + 1) > Length()) )
			// If the number of bits needed to not extend beyond a single block, *or* we're
			// looking at the very last block, then we only need to get bits from a single block.
			return (_GetBlock(block_pos) & (~(0xFFFF & (0xFFFF << bit_length)) << bit_pos)) >> bit_pos

		else
			// Otherwise, we have to correctly join bits from two different blocks.
			return ((_GetBlock(block_pos)   & (~(0xFFFF & (0xFFFF << bit_length)) <<     bit_pos)) >>      bit_pos)  | \
				   ((_GetBlock(block_pos+1) & (~(0xFFFF & (0xFFFF << bit_length)) >> (16-bit_pos))) << (16-bit_pos))