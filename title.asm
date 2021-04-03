B>type title.asm

.title	"TITLE PAGE"
.sbttl	"FRENZY"
.ident	TITLE
;~~~~~~~~~~~~~~~~~~~~~~~
;	TITLE PAGE
;_______________________
.insert equs
.define P[A]=[
.byte	^b'A
]
TITLE:: call	CLEAR#
	call	C.TITLE#	;for now
	call	CopyR#		;display copyright
; display STERN
	lxi	y,CROSS
	lxi	x,STERN
	lxi	h,12<8!16	;start pos
	lxi	d,5<8!4		;offsets
	call	PLOTER
; display FRENZY
	lxi	y,SQUARE
	lxi	x,FRENZY
	lxi	h,84<8!16	;start pos
	lxi	d,8<8!5		;offsets
	call	PLOTER		;**was plotes
	ret
; gamevoer frenzy
SmallTitle::
	lxi	y,Little
	lxi	x,FRENZY
	lxi	h,2<8!61	;start pos
	lxi	d,4<8!3		;offsets
	call	PLOTER
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; PLOTER
; Purpose: Diplays pattern using big patterns as pixel
; Inputs:
; DE = Yoffset,Xoffset
; HL = Y start pos,X start pos
; IX-> Display Data String (i.e. STERN)(*CharArray)
; IY-> Object to use as dots
; additional Regs:
; C = one bit mask
; B = DELAY on each dot
PLOTES: mvi	b,-1
	jmpr	Pl2
PLOTER: mvi	b,0
Pl2:	mvi	c,1		;first bit mask
..lop1: push	h		;save YX
	push	x		;save *CharArray
..lop2: mov	a,0(x)		;check bit for write
	ana	c		;is bit=1
	jz	..inc		;else skip
; plot *iy at H,L
	push	b		;save all
	push	d
	push	h
	call	RtoAx#		;convert hl
	xchg
	push	y		;get ob pointer
	pop	h		;to hl
	call	PLOT#
	pop	h		;restore all
	pop	d
	pop	b
	mov	a,b
	ora	a
	jz	..inc
	mvi	b,0
..l:	xtix
	xtix
	xtix
	xtix
	djnz	..l		;delay slightly
	mov	b,a
..inc:	mov	a,l		;x
	add	e		;xoffset
	mov	l,a		;x +=offset
	inx	x		;++CArray
	mov	a,0(x)		;test if at end of array
	ora	-1(x)		;both 0 means end
	jnz	..lop2		;go do next dot
	pop	x		;*CA=&start of array
	pop	h		;restore X to begin of line
	mov	a,h		;y
	add	d		;Yoffset
	mov	h,a		;y+=Yoffset
	slar	c		;maskbit=maskbit<<1
	jnz	..lop1		;if still a bit left do it
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Data for display
; organized as strips
;-------------------------------
STERN:
P	11001110
P	11011011
P	11011011
P	11111011
P	01110011
P	00000000
P	00000011
P	00000011
P	11111111
P	11111111
P	00000011
P	00000011
P	00000000
P	11111111
P	11111111
P	11011011
P	11011011
P	11000011
P	00000000
P	11111111
P	11111111
P	00011011
P	00011011
P	11111111
P	11101110
P	00000000
P	11111111
P	11111111
P	00001110
P	00011100
P	00111000
P	11111111
P	11111111
P	00000000
P	00000000

FRENZY:
P	11111111
P	11111111
P	00011011
P	00011011
P	00000011
P	00000011
P	00000000
P	11111111
P	11111111
P	00011011
P	00011011
P	11111111
P	11101110
P	00000000
P	11111111
P	11111111
P	11011011
P	11011011
P	11000011
P	11000011
P	00000000
P	11111111
P	11111111
P	00001110
P	00011100
P	00111000
P	11111111
P	11111111
P	00000000
P	11100011
P	11110011
P	11111011
P	11011111
P	11001111
P	11000111
P	00000000
P	00000111
P	00001111
P	11111100
P	11111100
P	00001111
P	00000111
.byte	0,0

CROSS:	.byte	1,4
P	01000000
P	11100000
P	11100000
P	01000000

SQUARE: .byte	1,9
P	01111100
P	10000100
P	10000100
P	10000100
P	11111100
P	10000100
P	10000100
P	10000100
P	11111000

Little: .byte	1,4
P	11000000
P	11000000
P	11000000
P	00000000

	.end
