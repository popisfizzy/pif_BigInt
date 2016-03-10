pif_BigInt/proc

	PrintBinary()
		. = ""
		var/BitLength = BitLength()
		for(var/i = 0, i < BitLength, i ++)
			. = "[Bit(i)]" + .

	PrintQuaternary()
		. = ""
		var/Max = BitLength() / 2
		for(var/i = 0, i < Max, i ++)
			. = "[BitsInteger(i*2, 2)]" + .

	PrintOctal()
		. = ""
		var/Max = round(BitLength() / 3) + 1
		for(var/i = 0, i < Max, i ++)
			. = "[BitsInteger(i*3, 3)]" + .

	PrintHexadecimal()
		. = ""
		var/Max = BitLength() / 4
		for(var/i = 0, i < Max, i ++)
			var/c = BitsInteger(i*4, 4)
			switch(c)
				if(0 to 9)
					. = "[c]" + .
				if(10)
					. = "a" + .
				if(11)
					. = "b" + .
				if(12)
					. = "c" + .
				if(13)
					. = "d" + .
				if(14)
					. = "e" + .
				if(15)
					. = "f" + .

	PrintBase64()
		. = ""
		var/Max = round(BitLength() / 6) + 1
		for(var/i = 0, i < Max, i ++)
			var/c = BitsInteger(i*6, 6)
			switch(c)
				if(0 to 25)
					// A (ascii 65) to Z (ascii 90)
					. = ascii2text(65 + c) + .
				if(26 to 51)
					// a (ascii 97) to z (ascii 122). Note that 97-26 = 71.
					. = ascii2text(71 + c) + .
				if(52 to 61)
					// 0 through 9.
					. = "[c-52]" + .
				if(62)
					. = "+" + .
				if(63)
					. = "/" + .

	// Shortcut methods.

	PrintBin()
		return PrintBinary()

	PrintOct()
		return PrintOctal()

	PrintHex()
		return PrintHexadecimal()