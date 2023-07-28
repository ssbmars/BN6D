VERBOSE equ 0

// GameName gets defined as a command line argument when building

ROMfldr equ "rom\\"
OUTfldr equ "out\\"
ASMfldr equ "asm\\"

INPUT_ROM	equ ROMfldr + GameName + ".gba"
OUTPUT_ROM	equ OUTfldr + "output_" + GameName + ".gba"
ADDR_LIST	equ ASMfldr + GameName + "_addr.asm"

FreeSpace	equ 0x08801000

.open INPUT_ROM, OUTPUT_ROM, 0x8000000
.include ADDR_LIST

.macro symoff
	.if VERBOSE == 0 :: .sym off :: .endif
.endmacro

.macro poool
	.sym off
	.pool
	.sym on
.endmacro


.include ASMfldr+ "bn6d.asm"

.close