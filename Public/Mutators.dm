pif_BigInt/proc

	SetSign(_sign = null)
		// If _sign is null, then the method will determine
		// the sign of the object. Otherwise, it will use the
		// incoming data to set the value of the block.

		if(_sign != null)
			// Data was passed, so we'll use it to determine the sign.
			src.sign = (_sign == 0) ? 0 : ( (_sign > 0) ? 1 : -1 )

		else
			// Otherwise, go ahead and determine the sign.

			if(src.LargestBit() == 1)
				// If the largest bit is equal to 1, then the object
				// is negative.
				_sign = -1
			else
				// If it's zero, then we have to check that there are
				// non-zero blocks.

				// First, we assume it's zero.
				_sign = 0

				// We start looking for through the blocks for a non-zero
				// block.
				var/Length = src.Length()
				for(var/i = 1, i <= Length, i ++)
					if(src._GetBlock(i) != 0)
						// If we find non-zero block, then the sign is
						// positive. Set _sign and break out of the loop.
						_sign = 1
						break

			// Set the sign to _sign, now that it should hold the value of
			// the sign of the object.
			src.sign = _sign

		// And return the new value of the object's sign.
		return src.Sign()

	SetLength(newLength = 1, pad = null)
		// This sets the block length of the source object to the specified value,
		// with an optional padding. If pad is not specified, it will be determined
		// based on the PadValue() function.

		// Set the pad value.
		pad = (pad == null) ? PadValue() : pad

		var/oldLength = src.Length()
		src.blocks.len = newLength

		if(newLength > oldLength)
			// If the we have added null blocks, then we need to loop through them
			// and give them a suitable value.

			for(var/i = oldLength + 1, i <= newLength, i ++)
				src._SetBlock(i, pad)

		return src.Length()