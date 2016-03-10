pif_BigInt/proc

	BitwiseNot()
		// Outputs the bitwise not of the source object.

		var
			pif_BigInt/N = new(src)
			NLength = N.Length()
		for(var/i = 1, i <= NLength, i ++)
			N._SetBlock(i, ~N._GetBlock(i))

		return N