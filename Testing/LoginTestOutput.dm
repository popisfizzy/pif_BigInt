#define DEBUG

proc
	MathematicaCheck(min = 1, max = BigInt_TestData.len)
		// This function outputs Mathematica code.

		var
			MathematicaVars = ""
			BigIntVars = ""

			MvsBI = ""

		for(var/i = min, i <= max, i ++)
			var/pif_BigInt
				a = BigInt_TestData[i]
				b = BigInt_TestData[(i % BigInt_TestData.len) + 1]

				o = a.Multiply(b)

			// Get the MathematicaVars output. These pairs will be computed by
			// Mathematica.

			var/aText = "16^^[a.PrintHex()]"
			if(a.Sign() < 0)
				// Used to convert it properly to two's complement in Mathematica.
				aText = "(-16^[4*a.Length()] + [aText])"

			var/bText = "16^^[b.PrintHex()]"
			if(b.Sign() < 0)
				bText = "(-16^[4*b.Length()] + [bText])"

			MathematicaVars += "Mathematica[i] = [aText] * [bText];\n"

			// BigIntVars output. These are computed by this library.

			var/oText = "16^^[o.PrintHex()]"
			if(o.Sign() < 0)
				oText = "(-16^[4*o.Length()] + [oText])"

			BigIntVars += "BigInt[i] = [oText];\n"

			// And the code that will compared them. It takes their difference, and
			// each result should be zero.

			MvsBI += "BaseForm\[Mathematica[i] - BigInt[i], 16\]\n"

		world << "<tt>[MathematicaVars]</tt>"
		world << "<tt>[BigIntVars]</tt>"
		world << "<tt>[MvsBI]</tt>"

proc/dec2bin(b)
	. = ""
	for(var/i = 0, i < 16, i ++)
		. = "[(b >> i) & 1]" + .

mob/Login()
	..()

	MathematicaCheck(1,1)