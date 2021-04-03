B>type align.asm

.title	"CrossHatch and Red Screen"
.sbttl	"FRENZY"
.ident	ALIGN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Do a cross-hatch display
;--------------------------------------
.insert equs
.extern C.DIPS,W.Fire
.extern ASHOW,CLEAR,LINE
; Put up cross-hatch on screen
ALIGN:: lxi	h,ScreenRAM	;start vertical lines
	mov	d,h
	mov	e,l
	mvi	M,1		;turn on one dot
	inx	h
	mov	m,e		;=0
	inx	h		;so 1 dot per 16
	lxi	b,EndScreen-(ScreenRAM+2)
	xchg
	ldir			;fill screen
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; now screen has vertical lines of dots
; fill in horizontal lines
;--------------------------------------
	lxi	h,ScreenRAM+Hsize*8	;start 8 lines down
	mov	d,h
	mov	e,l
	mvi	b,Hsize		;32 bytes across screen
Hloop:	mvi	M,-1		;fill in line
	inx	h
	djnz	Hloop
	lxi	b,20*Hsize	;drop down 20 lines
	dad	b		;and do it again
	xchg			;by copying top many times
	lxi	b,(EndScreen-ScreenRAM)-(28*Hsize)
	ldir
	call	C.DIPS		;set color ram to white
	call	W.Fire		;wait for fire button
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Make a red screen for purity adj
;--------------------------------------
	lxi	h,ScreenRAM	;fill screen
	lxi	d,ScreenRAM+1	;with -1's
	lxi	b,EndScreen-ScreenRAM	;to make
	mvi	M,-1		;white backgnd
	ldir
	lxi	h,ColorRAM	;fill color ram
	lxi	d,ColorRAM+1	;with 11's (RED)
	lxi	b,EndColor-ColorRAM
	mvi	M,11H		;red
	ldir
	call	W.Fire		;wait for fire button
	jmp	ALIGN		;jump back in a loop
.PAGE
.title	"Display ZPU dipsw and VFB switch ports"
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Display Switch Status
;-------------------------------
Linof	==	256*16

; Start of Main Test Sequence
DSPSW::
	di
	in	WHATI
	xra	a
	out	I.ENAB
	out	NMIOFF
	lxi	sp,SPos		;need a stack pointer

	call	CLEAR		;clear screen
	call	C.DIPS		;color screen

	lxi	h,ZPUSW		;message for zpu switches
	lxi	d,Linof*0+32	;on line 0
	call	SHOW

;	lxi	h,VFBSW		;message for vfb switches
	lxi	d,Linof*8+32	;on line 8
	call	SHOW

;	lxi	h,BITS		;message for bit position
	lxi	d,Linof*1+8	;on line 1
	call	SHOW

;	lxi	h,DEF		;message for character def
	lxi	d,Linof*13+16	;on line 13
	call	SHOW

	lxi	h,ScreenRAM+16*32*2-96
	call	LINE

	lxi	h,ScreenRAM+16*32*9-96
	call	LINE
..LOOP:
	lxi	d,Linof*2+8	;zpu switches line 2 - 6

	in	DIP1		;top dip
	call	SWSHOW		;zpu switches on = 1

	in	DIP2
	call	SWSHOW

	in	DIP3
	call	SWSHOW

	in	DIP4
	call	SWSHOW

	in	DIP5
	call	SWSHOW

	lxi	d,Linof*9+8	;vfb switches lines 9 - 11
	in	I.O1		;first connector
	call	SWSHWI		;vfb switches on = 0

	in	I.O2
	call	SWSHWI

	in	I.O3
	call	SWSHWI

	jmp	..LOOP
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	go show the string
;-------------------------------
SHOW:	mvi	B,0		;magic reg.
	jmp	ASHOW
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; general show switches routine 1 byte/line
; input de = crt x,y address for message (next line when done)
;	a = bit pattern 1 = on
;-------------------------------
SWSHWI: cma			;now 1 = on
SWSHOW: mvi	C,8		;8 bits / byte
..Loop: rar
	lxi	h,SWON		;assume switch on
	jrc	..sk1
	lxi	h,SWOFF		;switch was off
..sk1:
	push	psw		;save bits
	push	d		;save address
	push	b		;save bit counter
	call	SHOW
	pop	b		;restore registes
	pop	d
	pop	psw

	lxi	h,8*4		;next position on screen
	dad	d
	xchg

	dcr	c		;all bits displayed?
	jrnz	..Loop

	lxi	h,Linof-256	;point to next line
	dad	d		;for writing
	xchg

	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 .asciz Messages
;--------------------------------------
ZPUSW:	.asciz	"ZPU DIP SWITCHES"
VFBSW:	.asciz	"VFB SWITCHES"
BITS:	.asciz	"1   2	 3   4	 5   6	 7   8"
DEF:	.asciz	"0=OFF	1=ON"
SWON:	.asciz	"1"
SWOFF:	.asciz	"0"
	.end
