.gba

.if	AM_DEBUGGING
	//.include ASMfldr+ "debugging.asm"
.endif

//	run all other asm files here
//.include ASMfldr+ "file.asm"


//  ============  //	Hooks and small edits

//	.org 0x08000000

.if AM_DEBUGGING
	// boot to black screen with a very early hook
	.org 0x080000D0
		.arm
		ldr		r0,=DarkBoot1
		bx		r0
		poool
		DarkBoot1Return:
		.thumb

	//	maintain black screen during startup
	.org screenio1
		mov		r0,40h
	.org screenio2
		mov		r0,40h
	.org screenio3
		ldr		r0,=DarkBoot2|1
		bx		r0
		poool
		nop

	//	skip the capcom logo
	.org BootScene1
		mov		r0,10h
	.org BootScene2
		mov		r0,0Ch
.endif

// make it fade to a black screen when starting pvp

.org PVPFade	// pvp
	mov r0,0Ch
.org BossFade	//pve
	mov r0,0Ch
.org PVPUnfade	// triple battle
	mov r0,8h
.org PVPUnfade + 0x0C	// single battle
	mov r0,8h


// fix the glitch that allows decrossing
.org DecrossChecker
	nop

// disable TFC
.org DisableTFC
	bl		TFCstopper
/*
.org SetGrabTimerLong
	mov pc, lr

.org SetGrabTimerShort
	mov pc, lr
*/

.org IsPanelGrabbable
	mov r0, 1h
	mov pc, lr

.org AreaGrabHook
	bl		AreaGrabFix


// windrack: delay the movement of the invisible gusts so that players will get moved by the gusts regardless of their entity update order if they're hit point blank while they are being protected by a barrier

	// point to a new table of routines for windrack's logic
	.org RedirectWindrack
		.dw WindrackJumpTable

	// don't let the gusts move on the same frame they're spawned
	.org WindRStep2 - 0xA
		nop
		nop
// endrack

// BDT and Thunder: when the targeted character is on the same panel as the thunder ball, make the ball move in a relative "forward" direction instead of moving in a hardcoded direction that ignores which side spawned the thunder

	.org ThunderHook
	// the skipped bytes are a push r14 and an important routine,
	// easier to leave those intact
	.skip 0x2*3
	ldr		r2,=ThunderMove|1
	bx		r2
	poool
	nop
	freedspace1:
// thunder doneder



//  ============  //	Freed up space (from repointing existing functions)
// this space is from the Thunder code
.org freedspace1
	.sym off :: .area 0x080C95E6 - 0x080C957C, 0x0	:: .sym on
	nop

	TFCstopper:
	push	r14

	ldr r1,=2036840h
	ldrb	r0,[r1]
	cmp		r0,0xB
	blt		@@continue
	ldrb	r0,[r1,0x1]
	cmp		r0,0x0C
	beq		@@allowinput
	ldrb	r0,[r1,0x7]
	cmp		r0,0x6
	blt		@@continue
	add		r0,0x1
	cmp		r0,0x0A
	beq		@@allowinput
	strb	r0,[r1,0x7]

	@@continue:
	mov		r0,0x0
	tst		r0,r0
	pop		r15
	// to prevent TFC, return false on a bne check

	@@allowinput:
	mov		r1,r10
	ldr		r1,[r1,0x18]
	ldrh	r0,[r1,0x32]
	mov		r1,0x4
	and		r0,r1
	pop		r15
	poool


	AreaGrabFix:
	sub		r0,0x1
	cmp		r0,0x6
	sub		r1,0x1
	cmp		r1,0x3
	bcs		@@jump
	mov		r0,0x1
	mov		r15,r14
	@@jump:
	mov		r0,0x0
	mov		r15,r14



	.sym off :: .endarea :: .sym on
// end of freedspace1


// End of ROM

.org FreeSpace

//  ============  //	new routines go here

.align 4
.arm
.if AM_DEBUGGING
	DarkBoot1:
		mov		r0,12h
		mov		cpsr,r0
		ldr		r13,=0x3007F60
		// custom code part
		ldr		r0,=0x04000000
		mov		r1,40h
		strb	r1,[r0]
		add		r0,50h
		mov		r1,0FFh
		strb	r1,[r0]
		mov		r1,10h
		strb	r1,[r0,4h]

		ldr		r0,=DarkBoot1Return
		bx		r0
		poool
		.thumb

	DarkBoot2:
		mov		r0,40h
		ldr		r1,=0x08001778|1
		mov		r14,r15
		bx		r1
		ldr		r1,=0x0802F530|1
		mov		r14,r15
		bx		r1

		// now for the custom stuff
		ldr		r0,=0x04000000
		mov		r1,40h
		strb	r1,[r0]
		add		r0,50h
		mov		r1,0FFh
		strb	r1,[r0]
		mov		r1,10h
		strb	r1,[r0,4h]

		// apply it again later
		ldr		r0,=0x02009740
		mov		r1,0FFh
		strb	r1,[r0]
		mov		r1,10h
		strb	r1,[r0,4h]

		pop		r15
		poool
.endif


// chunks of existing code copied to free space so that custom code can be inserted where it used to be
PasteCodeChunk2:
	push	r14
	add		r4,r4,r0
	mov		r0,74h
	sub		r1,r4,1h
	//	safely write !! flag
	ldrb	r2,[r6,r0]
	orr		r1,r2
	strb	r1,[r6,r0]
	pop		r15

PasteCodeChunk1:
	push	r14
	ldrh	r0,[r7,2Eh]
	ldrb	r1,[r7,2h]
	cmp		r1,3h
	bne		@@skip
	mov		r2,78h
	ldrh	r3,[r6,r2]
	add		r3,r3,r0
	strh	r3,[r6,r2]
	@@skip:
	mul		r0,r4
	add		r1,r1,r1
	add		r1,82h
	ldrh	r2,[r6,r1]
	add		r2,r2,r0
	strh	r2,[r6,r1]
	mov		r0,r6
	pop		r15



// the entire function is taken directly from the game and pasted here so it can be modified more freely
ThunderMove:
BuffDeathThunder equ 1	// 0=go off field | 1=stay on field
FUNNYTHUNDER	equ 1	// 1=BDT can go diagonal and is harder to move out of bounds

	symoff
	.if FUNNYTHUNDER
	// r0 has target x
	// r1 has target y
	// return address is already pushed to stack
		@@xpos	equ [r5,12h]
		@@ypos	equ [r5,13h]
		@@level	equ r2,[r5,4h]
		@@xdir	equ r0,[r5,40h]
		@@ydir	equ r0,[r5,44h]
	cmp		r0,0h
	bne		@@targetfound
	ldrb	r3,@@ypos
	mov		r1,r3
	ldrb	r2,@@xpos
	mov		r0,r2
	@@targetfound:
	push	r0
	ldrb	r3,@@ypos	// y of self
	cmp		r1,r3
	beq		@@wipeypos
	b		@@decidey
	@@wipeypos:
	mov		r0,0h
	str		@@ydir
	b		@@gotoxcheck
	@@decidey:
	ldrb	r2,@@ypos
	cmp		r1,r2
	blt		@@yflip
	mov		r0,1h
	b		@@GoVertical
	@@yflip:
	mov		r0,0h
	sub		r0,1h
	@@GoVertical:
	ldr		r1,=6666h	// normal vertical speed
	ldrb	@@level
	cmp		r2,2h
	bne		@@LVcheck3
	ldr		r1,=999Ah	// faster vertical speed
	@@LVcheck3:
	mul		r0,r1
	str		@@ydir
	@@gotoxcheck:
	pop		r0
	ldrb	r2,@@xpos	// x of self
	cmp		r0,r2
	beq		@@wipexpos
	b		@@decidex
	@@wipexpos:
	mov		r0,0h
	str		@@xdir
	b		@@wrapup
	@@decidex:
	cmp		r0,r2
	blt		@@xflip
	@@difx:
	mov		r0,1h
	b		@@GoHorizontal
	@@xflip:
	mov		r0,0h
	sub		r0,1h
	b		@@GoHorizontal
	@@GoHorizontal:
	ldr		r1,=0AAABh	// normal horizontal speed
	ldrb	@@level
	cmp		r2,2h
	bne		@@LVcheck1
	ldr		r1,=10000h	// faster horizontal speed
	@@LVcheck1:
	mul		r0,r1
	str		@@xdir
	@@wrapup:
	mov		r0,3Ch		// normal move time (yes they hardcoded this info)
	ldrb	@@level
	cmp		r2,2h
	bne		@@LVcheck2
	mov		r0,28h		// faster move time
	@@LVcheck2:
	strh	r0,[r5,20h]
	pop		r15
	poool

	.else

	// r0 has target x
	// r1 has target y
	// return address is already pushed to stack
		@@xpos	equ [r5,12h]
		@@ypos	equ [r5,13h]
		@@level	equ r2,[r5,4h]
		@@xdir	equ r0,[r5,40h]
		@@ydir	equ r0,[r5,44h]

	cmp		r0,0h
	bne		@@targetfound
	@@checkfacing:
	bl		tmGetFacing
	b		@@GoHorizontal
	@@targetfound:
	ldrb	r3,@@ypos	// y of self
	cmp		r1,r3
	beq		@@samey

	ldrb	r2,@@xpos	// x of self
	cmp		r0,r2
	beq		@@samex

	@@samey:
	ldrb	r2,@@xpos
	cmp		r0,r2
	blt		@@xflip
	// new check, is x equal?
	cmp		r0,r2
	bne		@@difx
	bl		tmGetFacing
	.if BuffDeathThunder
	neg		r0,r0
	.endif
	b		@@GoHorizontal

	@@difx:
	mov		r0,1h
	b		@@GoHorizontal

	@@xflip:
	mov		r0,0h
	sub		r0,1h
	b		@@GoHorizontal

	@@samex:
	ldrb	r2,@@ypos
	cmp		r1,r2
	blt		@@yflip
	mov		r0,1h
	b		@@GoVertical
	@@yflip:
	mov		r0,0h
	sub		r0,1h

	@@GoVertical:
	ldr		r1,=6666h	// normal vertical speed
	ldrb	@@level
	cmp		r2,2h
	bne		@@LVcheck3
	ldr		r1,=999Ah	// faster vertical speed
	@@LVcheck3:
	mul		r0,r1
	str		@@ydir
	mov		r0,0h
	str		@@xdir
	b		@@setmovetime

	@@GoHorizontal:
	ldr		r1,=0AAABh	// normal horizontal speed
	ldrb	@@level
	cmp		r2,2h
	bne		@@LVcheck1
	ldr		r1,=10000h	// faster horizontal speed
	@@LVcheck1:
	mul		r0,r1
	str		@@xdir
	mov		r0,0h
	str		@@ydir

	@@setmovetime:
	mov		r0,3Ch		// normal move time (yes they hardcoded this info)
	ldrb	@@level
	cmp		r2,2h
	bne		@@LVcheck2
	mov		r0,28h		// faster move time
	@@LVcheck2:
	strh	r0,[r5,20h]
	pop		r15

// this routine will allow us to flip the movement direction if it was used by a player on the right side of the field
tmGetFacing:
	ldrb	r0,[r5,16h]
	ldrb	r1,[r5,17h]
	eor		r0,r1
	lsl		r0,1h
	sub		r0,1h
	neg		r0,r0
	mov		r15,r14
	poool
.endif
.sym on

.align 0x4
WindrackJumpTable:
	// 0 -> 1 -> 3 -> 2, spawn wind, linger for 1 frame, then start moving
	.dw WindRStep1|1
	.dw WindRWaitStep|1
	.dw DeleteSpell|1
	.dw WindRStep2|1

WindRWaitStep:
	// this just exists to stall the windrack gust logic for a frame before it starts moving
	push	r14
	// advance to next step
	mov		r0,0Ch
	str		r0,[r5,8h]

	pop		r15



// smile :D
.if GameName == "bn6f"
	.org 0x086E7DCC
	.import "smiles/FalzarSmiles.bin"
	.org 0x086E890C
	.import "smiles/SpoutGrey.img.bin"
	.import "smiles/ThankGrey.img.bin"
	.import "smiles/TenguGrey.img.bin"
	.import "smiles/GroundGrey.img.bin"
	.import "smiles/DustGrey.img.bin"
.elseif GameName == "bn6g"
	.org 0x086E5D50
	.import "smiles/GregarSmiles.bin"
	.org 0x086E6890
	.import "smiles/HeatGrey.img.bin"
	.import "smiles/ElecGrey.img.bin"
	.import "smiles/SlashGrey.img.bin"
	.import "smiles/EraseGrey.img.bin"
	.import "smiles/ChargeGrey.img.bin"
.endif

// Repoint megaman sprites
.org 0x08031CEC
;	.dw sussy1

// Putting images here
.org 0x08805000

sussy1:
;.import "art/sus1.bnsa"
