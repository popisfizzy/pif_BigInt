pif_BigInt/proc

	Length()
		// The number of blocks currently present in the pif_BigInt object.
		return src.blocks.len

	BitLength()
		// The number of bits currently present in the pif_BigInt object, which
		// is the number of blocks multiplied by the word length (i.e., 16).
		return src.Length() * 16

	Sign()
		// If sign is null, we will automatically recompute it.

		if(src.sign == null)
			src.SetSign(null)

		return src.sign