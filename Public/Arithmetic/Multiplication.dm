pif_BigInt/proc

	Multiply(pif_BigInt/Int)
		var
			// The result of multiplication.
			pif_BigInt/Product = new(0)

			// Current length of the product.
			ProductLength = 1

			// The sign of the final result.
			Product_sign

			// Used for the process of negating the product, if needed.
			Product_carry

			// Metadata about the source object.
			srcLength = src.Length()
			src_sign = src.Sign() || 1 // All we need to know is whether it's non-negative, so this changes a 0
									   // sign into a 1.

			// Used for caching values. More important if src_sign = -1.
			list/srcCache = new
			src_carry = 1

			// Metadata about the Int data.
			IntLength
			Int_type
			Int_sign = null

			Int_carry = 1

			// Used for concurrent addition of new blocks for each iteration.
			carry

		/* Figure out what kind of data was passed. */

		if(istype(Int))
			IntLength = Int.Length()
			Int_type = BIGINT
			Int_sign = Int.Sign() || 1

		else if(istext(Int))
			// Not yet implemented.
			Int_type = STRING

		/* else if(args.len > 1)
			IntLength = args.len
			Int_type = LIST

			Int = args.Copy() */

		else if(istype(Int, /list))
			IntLength = Int:len
			Int_type = LIST

			Int_sign = ((Int[1] & 0x8000) == 0) ? 1 : -1

		else if(isnum(Int))
			IntLength = 1
			Int_type = INTEGER
			Int_sign = (Int < 0) ? -1 : 1

		else
			throw EXCEPTION("Invalid or unknown data type for processing.")

		// Set the Product_sign, which we will now know (at least, we'll know whether
		// it's negative or non-negative, which is enough).
		Product_sign = Int_sign * src_sign

		/* Now proceed with the multiplication algorithm. */

		for(var/i = 1, i <= IntLength, i ++)
			var/IntBlock

			switch(Int_type)
				if(BIGINT)
					IntBlock = Int._GetBlock(i)
				if(LIST)
					IntBlock = Int[IntLength - i + 1]
				if(INTEGER)
					IntBlock = Int

			if( (IntBlock == 0) && (i != 1) && (i != IntLength) )
				// If IntBlock is 0, then just skip to the next block, as nothing significant
				// will occur during this iteration. We make an exception for 1, as we want to
				// cache the block values for the source object, and we make an exception for
				// IntLength, as that is when the conversion to negative happens.
				continue

			if(Int_sign == -1)
				// If Int is negative, then we'll convert the block to positive and handle the
				// change in sign at the end. The following uses the fact that, in two's complement
				// notation, -x = ~x + 1.

				IntBlock = ~IntBlock

				var
					IntBlock_byte1 =  IntBlock & 0x00FF
					IntBlock_byte2 = (IntBlock & 0xFF00) >> 8

				IntBlock_byte1 = IntBlock_byte1 + Int_carry
				IntBlock_byte2 = IntBlock_byte2 + ((IntBlock_byte1 & 0xFF00) >> 8)

				// This will be carried to the next block when changing it from negative to positive.
				// It should only be a 0 or a 1.
				Int_carry = (IntBlock_byte2 & 0xFF00) >> 8

				IntBlock = (IntBlock_byte1 & 0x00FF) | ((IntBlock_byte2 & 0x00FF) << 8)

			var
				// The nybbles of IntBlock.
				s = (IntBlock & 0xF000) >> 12
				t = (IntBlock & 0x0F00) >>  8
				u = (IntBlock & 0x00F0) >>  4
				v = (IntBlock & 0x000F)

			if((i == IntLength) && (Product_sign == -1))
				// If we've reached the last block of Int and the product should be negative, we'll start
				// the process of negating Product.

				// This is effectively the +1 part of the identity ~x = -x + 1 (an identity in two's complement
				// representation).
				Product_carry = 1
				for(var/k = 1, k < i, k ++)
					// We only go up to (i-1), as the rest will be handled within the nested loop.
					var
						ProductBlock = ~Product._GetBlock(k)

						byte1 = (ProductBlock & 0x00FF) + Product_carry
						byte2 = ((ProductBlock & 0xFF00) >> 8) + ((byte1 & 0xFF00) >> 8)

					Product_carry = (byte2 & 0xFF00) >> 1

					ProductBlock = (byte1 & 0x00FF) | ((byte2 & 0x00FF) << 8)
					Product._SetBlock(k, ProductBlock)

			// We never carry anything from the previous iteration.
			carry = 0

			for(var/j = 1, j <= srcLength, j ++)
				var/srcBlock

				if(i > 1)
					// If we're through the first iteration, the values should have been computed and
					// cached, so use them.
					srcBlock = srcCache[j]

				else
					// If we're still on the first iteration, then we need to compute the suitable values
					// for the source object's blocks and cache them. This does little if the source object
					// is positive, but it's very important if the source object is negative.

					srcBlock = src._GetBlock(j)

					if(src_sign == -1)
						// If src is negative, then as above we'll convert it to positive.
						srcBlock = ~srcBlock

						var
							srcBlock_byte1 =  srcBlock & 0x00FF
							srcBlock_byte2 = (srcBlock & 0xFF00) >> 8

						srcBlock_byte1 = srcBlock_byte1 + src_carry
						srcBlock_byte2 = srcBlock_byte2 + ((srcBlock_byte1 & 0xFF00) >> 8)

						src_carry = (srcBlock_byte2 & 0xFF00) >> 8

						srcBlock = (srcBlock_byte1 & 0x00FF) | ((srcBlock_byte2 & 0x00FF) << 8)

					// Cache the value.
					srcCache.len ++
					srcCache[j] = srcBlock

					if( (src_sign == -1) && (j == srcLength) && (src_carry != 0) )
						// If we're at the last block, but src_carry isn't zero, then we need to
						// add one more block and put src_carry at the end.
						srcLength ++

						srcCache.len ++
						srcCache[j] = src_carry

						src_carry = 0

				if((srcBlock == 0) && (carry == 0) && (Product_sign != -1) && (i != IntLength))
					// If srcBlock is zero and carry is zero, then nothing will happen *unless* we're
					// performing the negation process (i.e., the product is negative and we've reached
					// the last block of Int).
					continue

				var
					// Nybbles of srcBlock.
					w = (srcBlock & 0xF000) >> 12
					x = (srcBlock & 0x0F00) >>  8
					y = (srcBlock & 0x00F0) >>  4
					z = (srcBlock & 0x000F)

					// Now to perform the multiplication step. To begin, we break the produt into
					// 'chunks'. To understand these chunks, imagine that IntBlock and srcBlock are
					// wwritten as
					//
					//		IntBlock = (2**12)*s + (2**8)*t + (2**4)*u + v
					//		srcBlock = (2**12)*w + (2**8)*x + (2**4)*y + z.
					//
					// Then factor the product IntBlock*srcBlock, and group the terms based on their
					// coefficient, which will be powers of 2. Then ch24 will be those with a coefficient
					// of 2**24, ch20 will be those with a coefficient of 2**20, and so on. This method
					// allows the processor to do most of the heavy lifting for multiplication and
					// addition, leaving us to just bring things together in the correct fashion.

					// I could try and reduce this to 9 multiplications instead of the 16 here right now,
					// but after messing around it looks like at this level it'll be a pain to do, and
					// preliminary tests only suggest a 2% speed up. Honestly, it's not worth it at this
					// low a level, and the main speed gain will be by reducing the number of iterations
					// by using Keratsuba.

					                             // Maximum possible values.
					ch0  =                   v*z //   0x00E1 = 0000 0000 1110 0001
					ch4  =             u*z + v*y //   0x01C2 = 0000 0001 1100 0010
					ch8  =       t*z + u*y + v*x //   0x02A3 = 0000 0010 1010 0011
					ch12 = s*z + t*y + u*x + v*w //   0x0384 = 0000 0011 1000 0100
					ch16 = s*y + t*x + u*w       //   0x02A3 = 0000 0010 1010 0011
					ch20 = s*x + t*w             //   0x01C2 = 0000 0001 1100 0010
					ch24 = s*w                   //   0x00E1 = 0000 0000 1110 0001

					// Arrangement of chunks into blocks.
					//        (i+j+1)-th Block           (i+j)-th Block         (i+j-1)-th Block
					//          Byte 6     Byte 5        Byte 4     Byte 3        Byte 2     Byte 1
					//      +-----------+-----------++-----------+-----------++-----------+-----------+
					// ch0  |           |           ||           |           || xxxx xxxx | 1110 0001 |
					// ch4  |           |           ||           |      xxxx || 0001 1100 | 0010      |
					// ch8  |           |           ||           | xxxx 0010 || 1010 0011 |           |
					// ch12 |           |           ||      xxxx | 0011 1000 || 0100      |           |
					// ch16 |           |           || xxxx 0010 | 1010 0011 ||           |           |
					// ch20 |           |      xxxx || 0001 1100 | 0010      ||           |           |
					// ch24 |           | xxxx xxxx || 1110 0001 |           ||           |           |
					//      +-----------+-----------++-----------+-----------++-----------+-----------+
					// Sum  | 0000 0000 | 0000 0000 || 1111 1111 | 1111 1110 || 0000 0000 | 0000 0001 | (0x0000FFFE0001)
					//      +-----------+-----------++-----------+-----------++-----------+-----------+

					// Now, we take the above and convert them into the corresponding bytes, while
					// summing them into the appropriate bytes.
					byte1 =       (ch0 & 0x00FF) + ((ch4 & 0x000F) << 4)
					byte2 =                        ((ch4 & 0x0FF0) >> 4) +  (ch8 & 0x00FF)       + ((ch12 & 0x000F) <<  4)
					byte3 = carry                                        + ((ch8 & 0x0F00) >> 8) + ((ch12 & 0x0FF0) >>  4) +  (ch16 & 0x00FF)       + ((ch20 & 0x000F) << 4)
					byte4 =                                                                        ((ch12 & 0xF000) >> 12) + ((ch16 & 0xFF00) >> 8) + ((ch20 & 0x0FF0) >> 4) + (ch24 & 0xFFFF)

					// Product blocks at positions (i+j)-1 and (i+j)+0 respectively.
					ProductBlock_n1 = (ProductLength < (i+j-1)) ? 0x0000 : Product._GetBlock(i+j-1)
					ProductBlock_0  = (ProductLength < (i+j))   ? 0x0000 : Product._GetBlock(i+j)

				// Now we add the current value of the ProductBlocks to bytes one through four, in the appropriate manner
				// (i.e., accounting for their binary positions).
				byte1 = byte1 + ( ProductBlock_n1 & 0x00FF)
				byte2 = byte2 + ((ProductBlock_n1 & 0xFF00) >> 8) + ((byte1 & 0xFF00) >> 8)
				byte3 = byte3 + ( ProductBlock_0  & 0x00FF)       + ((byte2 & 0xFF00) >> 8)
				byte4 = byte4 + ((ProductBlock_0  & 0xFF00) >> 8) + ((byte3 & 0xFF00) >> 8)

				// This will be the amount carried over to the next iteration.
				carry = (byte4 & 0xFF00) >> 8

				if((i == IntLength) && (Product_sign == -1))
					// If the end product is negative, we'll alter the bytes for ProductBlock_n1 to
					// adjust accordingly. We don't necessarily alter the bytes for ProductBlock_0, as
					// they will be manipulated for the next iteration in all likelihood.

					byte1 = (~byte1 & 0x00FF) + Product_carry
					byte2 = (~byte2 & 0x00FF) + ((byte1 & 0xFF00) >> 8)
					Product_carry = (byte2 & 0xFF00) >> 8

					if(j == srcLength)
						// If we're at the end, though, we can edit ProductBlock_0's bytes.

						byte3 = (~byte3 & 0x00FF) + Product_carry
						byte4 = (~byte4 & 0x00FF) + ((byte3 & 0xFF00) >> 8)

				// This makes sure each of these is only a single byte of non-zero data, so we can
				// safely OR them together.
				byte1 = ~~(byte1 & 0x00FF)
				byte2 = ~~(byte2 & 0x00FF)
				byte3 = ~~(byte3 & 0x00FF)
				byte4 = ~~(byte4 & 0x00FF)

				// Reassign the product blocks by joinin the bytes together in the proper way.
				ProductBlock_n1 = byte1 | (byte2 << 8)
				ProductBlock_0  = byte3 | (byte4 << 8)

				// Allocate space in the ProductBlock object as needed.

				if( (ProductLength < (i+j)) && (ProductBlock_0 != 0x0000) )
					Product.SetLength(i+j, 0x0000)
					ProductLength = i+j

				if( (ProductLength < (i+j-1)) && (ProductBlock_n1 != 0x0000) )
					Product.SetLength(i+j-1, 0x0000)
					ProductLength = i+j-1

				// And store the new blocks, provided space has been allocated for them.
				if(ProductLength >= (i+j-1)) Product._SetBlock(i+j-1, ProductBlock_n1)
				if(ProductLength >= (i+j))   Product._SetBlock(i+j,   ProductBlock_0)

		// And finally, we check the most significant bit of the product. If that bit doesn't match the sign
		// of the product, we add a new block with the proper value.

		var/LastBlock = Product._GetBlock(ProductLength)
		if(     (Product_sign ==  1) && ((LastBlock & 0x8000) != 0)) Product.Expand(1, 0x0000)
		else if((Product_sign == -1) && ((LastBlock & 0x8000) == 0)) Product.Expand(1, 0xFFFF)

		// Set the sign, at least if we really know it. If Product_sign == -1, then it's definitely negative. If
		// Product_sign == 1, then it's either positive or zero. In the latter case, we mark it as null so that
		// it will be evaluated when needed.
		Product.SetSign(
			(Product_sign == -1) ? -1 : null
		)

		// And output the final result.
		return Product

	_KaratsubaMultiplication(list/A, list/B)
		// Implements the Karatsuba algorithm. This should be 'private', and only called directly by the
		// /pif_BigInt.Multiply() method. A and B should have their blocks in increasing order of significance.
		// I.e., if the input is list(0xABCD, 0xEF01), then that is interpreted as 0xEF01ABCD.

		if( (A.len == 1) && (B.len == 1) )
			// If they have a length of 1, then we can directly compute their product.

			// Return value. .[1] is least significant ,and .[2] is most significant. The
			// largest possible value wil lbe 0xFFFE 0001, corresponding to
			// . = list(0x0001, 0xFFFE).
			. = list(0, 0)

			var
				// Nybbles of A.
				s = (A[1] & 0xF000) >> 12
				t = (A[1] & 0x0F00) >>  8
				u = (A[1] & 0x00F0) >>  4
				v =  A[1] & 0x000F

				// Nybbles of B.
				w = (B[1] & 0xF000) >> 12
				x = (B[1] & 0x0F00) >>  8
				y = (B[1] & 0x00F0) >>  4
				z =  B[1] & 0x000F

				// See the Multiply() method for the logic behind the following.
				ch0  =                   v*z
				ch4  =             u*z + v*y
				ch8  =       t*z + u*y + v*x
				ch12 = s*z + t*y + u*x + v*w
				ch16 = s*y + t*x + u*w
				ch20 = s*x + t*w
				ch24 = s*w

				byte1 =                           (ch0 & 0x00FF) + ((ch4 & 0x000F) << 4)
				byte2 = ((byte1 & 0xFF00) >> 8) +                  ((ch4 & 0x0FF0) >> 4) +  (ch8 & 0x00FF)       + ((ch12 & 0x000F) <<  4)
				byte3 = ((byte2 & 0xFF00) >> 8) +                                          ((ch8 & 0x0F00) >> 8) + ((ch12 & 0x0FF0) >>  4) +  (ch16 & 0x00FF)       + ((ch20 & 0x000F) << 4)
				byte4 = ((byte3 & 0xFF00) >> 8) +                                                                  ((ch12 & 0xF000) >> 12) + ((ch16 & 0xFF00) >> 8) + ((ch20 & 0x0FF0) >> 4) + (ch24 & 0xFFFF)

			.[1] = (byte1 & 0x00FF) | ((byte2 & 0x00FF) << 8)
			.[2] = (byte3 & 0x00FF) | ((byte4 & 0x00FF) << 8)

		else if( (A.len > 1) && (B.len > 1) )
			// Otherwise, we perform another step of the Karatsuba algorithm.
			var
				Length = A.len

				// The size of the groups we will apply this function to.
				Span = Length / 2

				list
					// Least and most significant halves of A and B, respectively.
					A0 = A.Copy(1, Span+1)
					A1 = A.Copy(Span+1)

					B0 = B.Copy(1, Span+1)
					B1 = B.Copy(Span+1)

					// The differences A1-A0 and B0-B1, respectively.
					A_diff
					B_diff

					// The products A1*B1, A_diff*B_diff, and A0*B0, respectively.
					P2
					P1
					P0

			/* Compute the differences. We can compute these at the same time, as
			   they are the same length. */
			A_diff = new
			B_diff = new

			A_diff.len = Span
			B_diff.len = Span

			// Set to one for computing the negatives of A0 and B1, respectively.
			var
				A_carry = 1
				B_carry = 1

			for(var/i = 1, i <= Span, i ++)
				// See the Subtraction() method in Subtraction.dm for the logic behind the following.
				var
					A0Block = ~A0[i]
					A1Block =  A1[i]

					A_diff1 = (A1Block & 0x00FF) + (A0Block & 0x00FF) + (A_carry & 0x00FF)
					A_diff2 = ((A1Block & 0xFF00) >> 8) + ((A0Block & 0xFF00) >> 8) + ((A_carry & 0xFF00) >> 8) \
							  + ((A_diff1 & 0xFF00) >> 8)

					B1Block = ~B1[i]
					B0Block =  B0[i]

					B_diff1 = (B0Block & 0x00FF) + (B1Block & 0x00FF) + (B_carry & 0x00FF)
					B_diff2 = ((B0Block & 0xFF00) >> 8) + ((B1Block & 0xFF00) >> 8) + ((B_carry & 0xFF00) >> 8) \
							  + ((B_diff1 & 0xFF00) >> 8)

				A_carry = (A_diff2 & 0xFF00) >> 8
				A_diff[i] = (A_diff1 & 0x00FF) | ((A_diff2 & 0x00FF) << 8)

				B_carry = (B_diff2 & 0xFF00) >> 8
				B_diff[i] = (B_diff1 & 0x00FF) | ((B_diff2 & 0x00FF) << 8)

			// Recursively compute P2, P1, and P0.
			P2 = .(A1, B1)
			P1 = .(A_diff, B_diff)
			P0 = .(A0, B0)

			/* Now we sum P0, P1, and P2 with the appropriate factors. That is, by effectively bitshifting
			   P1 and P2 by a certain amount as a function of the span. */

			// P0 has a 'bitshift/multiplication' factor of 1, so just begin the addition process by assigning
			// it to ., as it will always be returned.
			. = P0

			// Carry for the addition operation.
			var/carry = 0

			return P1

	Square()
		return src.Multiply(src)

	Power(n)
		// n is a non-negative integer, so n <= 65535 in all likelihood.

		// If you reach the point that you'd like me to implement use a BigInt instead of a DM integer, you are
		// probably doing things horribly wrong. The smallest (positive) integer that would be relevant here is
		// 2, so that would be 2**65536, which would require 65536 bits (8192 bytes) to store, and is well beyond
		// the scope of this library.

		var/pif_BigInt
			Int = new(1)
			Tracker = new(src)

		while(n != 0)
			// Implementation of exponentiation by squaring.

			if((n & 0x0001) == 1)
				Int = Int.Multiply(Tracker)

			Tracker = Tracker.Square()
			n >>= 1

		return Int

#define	DEBUG

mob/Login()
	..()

	var/pif_BigInt/A = new(0x0001)
	var/list/L = A._KaratsubaMultiplication(list(0x0001, 0x0002), list(0x0003, 0x0004))

	for(var/i = 1, i <= L.len, i ++)
		world << "<tt>block [i] => [L[i]]</tt>"