pif_BigInt/proc

	PadValue()
		// Determines the pad for expansion based on the largest bit. If the largest bit
		// is 1, then we pad with 0xFFFF. If the largest bit is 0, we pad with 0x0000. This
		// is based on the way two's complement works.
		return (LargestBit() == 1) ? 0xFFFF : 0x0000

	// General sign properties of the object.

	IsPositive()
		return src.Sign() == 1

	IsNonPositive()
		return src.Sign() != 1

	IsZero()
		return src.Sign() == 0

	IsNonZero()
		return src.Sign() != 0

	IsNegative()
		return src.Sign() == -1

	IsNonNegative()
		return src.Sign() != -1