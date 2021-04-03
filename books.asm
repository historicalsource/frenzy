B>type books.asm

.title	"Show Book-Keeping"
.sbttl	"FRENZY"
.ident	BOOKS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Book keeping stuff
;_______________________________
.insert equs
.extern MAIN,SHOWC,CLEAR,RtoA,SHOWN,C.BOOKS,Zap
.extern S.Fire,S.Book
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 Show book-keeping
;_______________________________
BOOKS::
	xra	a		;turn off interrupts
	out	I.ENAB
	in	WHATI		;clear any pending interrupts
	lxi	sp,SPos		;reset stack pointer
..T1:	CALL	S.Book
	jrnz	..T1
	call	CLEAR		;erase screen
	call	C.BOOKS		;color it for book-keeping
	di			;re DI cuz CLEAR does EI

	lxi	h,Strings	;point to book.keeping table
	mvi	C,-1		;item number=c
..loop:
	inr	c		;->next item
	mov	a,c		;test for end of table
	cpi	NItems
	jz	..exit
..skip:
	call	SCROLL		;scroll up to make room for text
	push	b
	mvi	B,0		;plop write
	lxi	d,256*207	;at x=0 y=207
	call	ASHOW		;show the text
	pop	b
	call	SCROLL		;make room for number
..Show:
	call	ItemShow
..wait:
	call	S.Book		;door switch
	jrz	..tst2
	call	Debounce
..deb:	call	S.Book		;wait for debounce
	jrnz	..deb
	call	Debounce
	jmp	..loop		;do it again
..tst2:
	call	S.Fire
	jrz	..wait
	call	ItemClear	; clear this book-keeping
	jmpr	..Show		;show it

..exit: call	S.Book
	jrnz	..exit
	call	Debounce
	jmp	MAIN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Subroutines for book-keeping
;-------------------------------
; Show Item #(C) in hex/BCD
;_______________________________
ItemShow:
	push	b		;save registers
	push	h
	call	ItemPtr
	xchg
	lxi	h,0		;make stack frame
	push	h
	push	h
	push	h
	dad	sp		;point hl->stack frame
	call	MOVEN		;move number
	lxi	d,207		;at x=0,y=207
	call	SSHON		;show number
	pop	h		;remove stack frame
	pop	h
	pop	h
POPER:	pop	h		;restore registers
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Clear Item #(C) in hex/BCD
;_______________________________
ItemClear:
	push	b
	push	h
	mov	a,c
	cpi	NItems-1
	jrnz	..
	inr	c		;special for high scores
..:	call	ItemPtr
	dcx	h		;->xsum
	inr	b		;+1 for xsum byte
ClearLoop:
	mvi	M,0
	inx	h
	djnz	ClearLoop
	JMPR	POPER
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Increment Item #(C) in BCD nibbles
;_______________________________
ItemInc::
	push	psw
	push	b
	push	d
	push	h
	call	ItemPtr		;get hl,b
	mvi	D,0		;-> end of BCD
	mov	e,b
	dcr	e		;not beyond end
	dad	d
;DE useable now
;BCD is one digit per byte in upper half of byte
	mvi	C,10H		;inc BCD by 1
	mvi	e,0		;xsum nibble
Lip:	mov	a,m		;get digit
	ani	0F0H		;mask garbage
	add	c		;add C
	daa			;decimal adjust
	mov	m,a		;store back in nibble RAM
	jrc	..con		;if no carry clear C
	mvi	c,0
..con:	dcx	h		;point to next msd
	add	e		;add in xsum
	mov	e,a		;save xsum
	djnz	Lip		;one less digit to do
	mov	m,e		;store xsum
	pop	h
	pop	d
	pop	b
	pop	psw
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Get info on Item #(C) in hex/BCD
; output:hl->item b=# of bytes
;_______________________________
ItemPtr::
	lxi	h,Items		;->Item[0]
	mov	e,c
	mvi	D,0
	dad	d		;->Item[b]
	dad	d		;->Item[2*b]
	dad	d		;->Item[3*b]
	mov	e,m		;low address
	inx	h
	mov	d,m		;address of item
	inx	h
	mov	b,m		;number of nibbles in item
	xchg
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Move @DE,@DE+1 to @HL for B NIBBLES
;_______________________________
MOVEN:: push	h		;save all regs
	push	d
	push	b
	srar	b		;divive nibbles by 2
..lp:	ldax	d		;get a nibble
	inx	d		;point to next
	ani	0F0H		;isolate battery half
	mov	c,a		;save in C
	ldax	d		;get next nibble
	inx	d		;point at next
	rlc			;isolate battery half into
	rlc			;lower nibble
	rlc
	rlc
	ani	0FH		;mask off battery ram
	ora	c		;or in high nible
	mov	m,a		;store at HL
	inx	h		;point at next
	djnz	..lp		;two ess nibbles to do
	pop	b		;restore
	pop	d
	pop	h
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show # at hl,b digits,e=y position
;_______________________________
SSHON:	push	b		;save all
	push	d
	push	h
	mov	d,e		;move Y position to D
	mvi	E,0		;set X to 0
	call	SHOWN		;show number
	pop	h
	pop	d
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Scroll Screen and Erase Area for Show
;_______________________________
SCROLL:: push	b		;save all
	push	d
	push	h
	lxi	b,206*Hsize	;size of area to move
	lxi	d,ScreenRAM	;at starting address
	lxi	h,16*Hsize+ScreenRAM	;move up 16 lines
	ldir
	xchg
	lxi	b,16*Hsize	;erase 16 lines at bottom
	call	Zap
	pop	h		;restore all
	pop	d
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show A String
; hl->string,de=y and x,b=magic
;_______________________________
ASHOW:: xchg			;relabs take coords in HL
	call	RtoA		;convert coordinates
	xchg
AS.L:	mov	c,m		;get character
	call	SHOWC		;show it
	inx	d		;point to next screen byte
	inx	h		;point to next letter
	mov	b,a		;save magic/shift
	mov	a,m		;test next letter
	ora	a		;if 0 leave
	mov	a,b		;restore magic/shift
	jnz	AS.L		;else loop
	inx	h		;skip over 0 byte
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Delay for time here
;_______________________________
Debounce:
	mvi	b,0		;adjust for best response
..lop:	xtix			;long time instr
	xtix
	xtix
	xtix
	djnz	..lop
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check the XSUMs and zap bad ones
;_______________________________
CheckBooks::
	mvi	c,0		;get 1st item
..lp1:	call	ItemPtr		;get the pointers
..do:	dcx	h		;->xsum
	mov	a,m		;get xsum
	ani	0F0h
	EXAF
	mvi	d,0		;temp xsum
..lp2:	inx	h		;->next byte
	mov	a,m		;get book nibble
	ani	0F0h		;isolate nibble
	add	d		;add xsum
	mov	d,a		;save
	djnz	..lp2		;for b nibbles
	EXAF			;get original xsum
	cmp	d		;temp sum the same?
	cnz	ItemClear	;no-clear item
	inr	c		;goto next item
	mov	a,c
	cpi	NItems-1	;all but high scores
	jrc	..lp1
; do high scores as big number
	rnz
	inr	c		;use special item#10
	jmpr	..lp1
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; book-keeping tables
;
; macro for setting up book-keeping
;
.define ITEM[Address,Length]=[
	.word	Address
	.byte	Length
]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; pointers and strings for book items
;_______________________________
Items:
	ITEM	CREDITS,2
	ITEM	Chute1,8
	ITEM	Chute2,8
	ITEM	Play1,6
	ITEM	Play2,6
	ITEM	Plays,6
	ITEM	ScoreSum,12
	ITEM	PlayTime,12
	ITEM	OnTime,12
	ITEM	HIGH2,6
NItems==10	
	ITEM	HIGH2,12*5	;special for clearing
Strings:
	.asciz	"Credits"
	.asciz	"Chute 1"
	.asciz	"Chute 2"
	.asciz	"1 Player Games"
	.asciz	"2 Player Games"
	.asciz	"Total Plays"
	.asciz	"Total Score"
	.asciz	"Total Seconds of Play"
	.asciz	"Total Seconds Game On"
	.asciz	"High Scores"

	.end
