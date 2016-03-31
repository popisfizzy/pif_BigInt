// It's faster to make this a macro than a method, and it has a very specific name
// so it won't cause clashes with other methods unless someone is being obtuse.
#define	pif_BigInt_InBounds(i)	((1 <= (i)) && ((i) <= src.Length()))

pif_BigInt/proc

	_GetBlock(i)
		if(pif_BigInt_InBounds(i))
			return src.blocks[i]

		else
			throw EXCEPTION("Attempted to access invalid block in /pif_BigInt object.")

	_SetBlock(i, j)
		if(pif_BigInt_InBounds(i))
			src.blocks[i] = j
			return src.blocks[i]

		else
			throw EXCEPTION("Attempted to chage invalid block on /pif_BigInt object.")

#undef	pif_BigInt_InBounds

/*
	_AddAtBlock(int, block_pos = 1)
		var
			srcLength = src.Length()
			carry = int

			terminate

		for(var/i = block_pos, i <= srcLength, i ++)
			var
				srcBlock = src._GetBlock(i)

				B1 = (srcBlock & 0x00FF) + (carry & 0x00FF)
				B2 = ((srcBlock & 0xFF00) >> 8) + ((carry & 0xFF00) >> 8) + ((B1 & 0xFF00) >> 8)

				newBlock = (B1 & 0x00FF) | ((B2 & 0x00FF) << 8)
			carry = (B2 & 0xFF00) >> 8

			src._SetBlock(i, newBlock)

			if(terminate)

				if(newBlock == 0x000)
					src.Contract(1)

				break

			if( (i == srcLength) && (carry != 0) )
				src.Expand(1, 0x000)

				srcLength ++
				terminate = TRUE

			if(carry == 0)
				break

		src.sign = null
		return src */