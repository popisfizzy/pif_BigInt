/*

// Javascript code for generating this test data. Uses jQuery.

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

var HexDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B',
                 'C', 'D', 'E', 'F'];

var Ints = 100;
var MinBlocks = 50;
var MaxBlocks = 50;

var BigIntBlocks = new Array(Ints);
for(var i = 0; i < Ints; i ++)
{
    var jMax = getRandomInt(MinBlocks, MaxBlocks);
    var Blocks = new Array(jMax);

    for(var j = 0; j < jMax; j ++)
    {
        var S = "0x";
        for(var k = 0; k < 4; k ++)
        {
            S += HexDigits[getRandomInt(0, 14)];
        }

        Blocks[j] = S;
    }
    BigIntBlocks[i] = Blocks;
}

$("#output").append("var/list/BigInt_TestData = list(");
for(var i of BigIntBlocks)
{
    $("#output").append("\n\tnew /pif_BigInt(" + i +"),");
}
$("#output").append("\n)");

*/



var/list/BigInt_TestData = list(
	new /pif_BigInt(0x1DA9),
	new /pif_BigInt(0xDEBE),
	new /pif_BigInt(0xAE41),
	new /pif_BigInt(0xC1A3),
	new /pif_BigInt(0xB61C),
	new /pif_BigInt(0x233A),
	new /pif_BigInt(0x2DE6),
	new /pif_BigInt(0xE91E),
	new /pif_BigInt(0xDDB9),
	new /pif_BigInt(0x7CC6),
	new /pif_BigInt(0x29D2),
	new /pif_BigInt(0x70A7),
	new /pif_BigInt(0xADD6),
	new /pif_BigInt(0x4B6B),
	new /pif_BigInt(0xE180),
	new /pif_BigInt(0xEE3C),
	new /pif_BigInt(0xD7E2),
	new /pif_BigInt(0x1A06),
	new /pif_BigInt(0xE653),
	new /pif_BigInt(0xA981),
	new /pif_BigInt(0x4608),
	new /pif_BigInt(0xE639),
	new /pif_BigInt(0x1404),
	new /pif_BigInt(0x42CB),
	new /pif_BigInt(0x4479),
)

