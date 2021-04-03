B>type bolts.asm

.title	"PLASMA BOLTS"
.sbttl	"FRENZY"
.ident	BOLTS
.insert equs
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Bolt Data Structure
;	bit number
; +---7-+---6-+---5-+---4-+---3-+---2-+---1-+---0-+
; |down | up  |right| left|	Length of	  |	VX.VY
; | v	| ^   | >   | <	  |	Bolt 1-6	  |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; BUL1:
;	---- VX.VY	[DURL in top,length in bottom]
;	---- PX		[position in x]
;	---- PY		[ "	in y]
;	 .
;	 :
;	---- oldX	[Old positions *6]
;	---- oldY
;------------------------
;	Equates
VX.VY	==	0		; byte offsets to bolt contents
PX	==	1
PY	==	2
LEFT	==	0		; direction bit numbers
RIGHT	==	1
UP	==	2
DOWN	==	3
GREY	==	77H		;mirror color
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Do all bolts
;_______________________________
BUL.V:: exx
	push	b		;set up wall color in alt set
	lda	Wcolor
	mov	b,a		;save
	ani	0F0H		;hi nib in C
	mov	c,a
	mov	a,b		;lo nib in b
	ani	0Fh
	mov	b,a
	exx
	mvi	B,2		;# man's bolts
	call	BOLT		;do 2 bolts
	mvi	B,2		;# man's bolts
	call	BOLT		;do 2 bolts
	mvi	b,BOLTS		;do all bolts
	call	BOLT
	exx
	pop	b
	exx
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vector (B) Bolts
;_______________________________
BOLT:	lxi	h,BUL1		;-> at 1st bolt
B.LOP:	push	b		;save counter
	push	h		;save pointer
	call	VEC.B		;erase/write a single bolt
	pop	h		;restore pointer
	pop	b		;restore counter
	lxi	d,Blength	;point at next bolt
	dad	d
	djnz	B.LOP		;do for B bolts
	ret
.page
.sbttl	/Erase Bolts/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Vector Bolts
;_______________________________
; HL->bolt top
VEC.B:
	mov	a,m		;vx.vy
	PUSH	PSW		;save vxy.len
	ani	0Fh		;isolate length
	jrnz	..cont
	POP	PSW
	RET
; ERASE Oldest position
..cont:
	lxi	b,PX
	dad	b		;->PX
	add	a		;double length
	mov	c,a		;bc=length*2
	dad	b		;->oldestX
	mov	e,m		;oldX
	inx	h		;oldestY
	mov	d,m		;oldY
	xchg
	mov	a,l
	ora	h		;no write if 0
	jrz	..skip
;BC=Length, DE->OldestY, HL=YX
	call	RELX		;convert to screen coords
	mvi	M,80h		;write dot
..skip:
	POP	PSW		;restore vxy.len
	ani	0F0h		;check if still writing
	jrnz	..ok
	lxi	h,-1
	dad	d
	dsbc	b		;->vxy.len
	dcr	M		;one less in length
	RET
; Move array of old positions down
..ok:	mov	h,d
	mov	l,e		;->oldestY
	dcx	h
	dcx	h		;->previous
	LDDR			;move down
	inx	h		;->px
; Update coords & WRITE DOT
; A=Vxy&F0, BC=0, DE->newest, HL->PX
	rrc			;do table jump
	rrc
	rrc
	mov	c,a		;bc=offset (DURL*2)
	xchg			;de->px
	lxi	h,JTable	;look up vectoring
	dad	b		;add offset
	mov	a,m		;routine in table
	inx	h		;and jump to it
	mov	h,m
	mov	l,a
	xchg
	mov	c,m
	inx	h
	mov	b,m		;bc=YX
	xchg
	pchl			;jump
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Update Coords
;_______________________________
JTable: .word	Rstop	;0
	.word	RLeft	;1
	.word	RRight	;2
	.word	Rstop	;3
	.word	RUp	;4
	.word	RUL	;5
	.word	RUR	;6
	.word	Rstop	;7
	.word	RDown	;8
	.word	RDL	;9
	.word	RDR	;10
	.word	Rstop	;11
	.word	Rstop	;12
	.word	Rstop	;13
	.word	Rstop	;14
	.word	Rstop	;15
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; all these routines get as input
; BC=pYpX, de->pY, hl=label address
;_______________________________
Rstop:	xchg			;hl->py
Stop:	xra	a		;0
	mov	m,a		;py=0
	dcx	h		;->px
	mov	m,a		;px=0
	dcx	h		;->vxy.len
	mov	a,m		;get vxy.len
	ani	0Fh		;leave length
	mov	m,a		;stop bolt
	RET
;set to 4 to protect outer walls
wallo	==	0
.define ULIMIT=[mov	a,b
	cpi	4+wallo		;;check limit
	jrc	STOP
]
.define DLIMIT=[mov	a,b
	cpi	200-wallo
	jrnc	STOP
]
.define RLIMIT=[mov	a,c
	cpi	252-wallo
	jrnc	STOP
]
.define LLIMIT=[mov	a,c
	cpi	8+wallo
	jrc	STOP
]

RUp:	xchg			; hl->py de=YX
	dcr	b		;y--
	ULIMIT
	jmp	Writ

RDown:	xchg
	inr	b		;y++
	DLIMIT
	jmp	Writ

RRight: xchg
	inr	c		;x++
	RLIMIT
	jmp	Writ

RLeft:	xchg
	dcr	c		;x--
	LLIMIT
	jmp	Writ

RUL:	xchg
	dcr	c		;x--
	dcr	b		;y--
	ULIMIT
	LLIMIT
	jmp	Writ

RUR:	xchg
	inr	c		;x++
	dcr	b		;y--
	ULIMIT
	RLIMIT
	jmp	Writ

RDL:	xchg
	dcr	c		;x--
	inr	b		;y++
	DLIMIT
	LLIMIT
	jmp	Writ

RDR:	xchg
	inr	c		;x++
	inr	b		;y++
	DLIMIT
	RLIMIT
	jmp	Writ
.sbttl	/Write Dots/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Write the Dot
;_______________________________
; hl->py,bc=YX
Writ:	mov	m,b		;update py
	dcx	h		;->px
	mov	m,c		;update px
	xchg			;de->px, hl?
	mov	h,b		;get pY
	mov	l,c		;pX
	call	RELX		;convert to screen addr
	mvi	M,80h		;write the dot
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Check for intercepts
;_______________________________
;BC=yx,DE->px, hl->screen
	in	WHATI
	rlc
	RNC
; Erase dot
	mvi	m,80h		;erase the dot
	shld	Temp		;save address for reflect
	dcx	d		;->vxy.len
; Hit Check by looking at the color bolt hit
	push	b		;save YX
	srlr	b		;index the 4x4 box
	srlr	b		;y/2
	srlr	b		;YX/8
	rarr	c
	srlr	b
	rarr	c
	srlr	b
	rarr	c		;carry=Low nibble
	exaf
	lda	Flip		;test cocktail
	ora	a
	jz	..norm
	lxi	h,EndColor
	dsbc	b		;subtract box offset
	pop	b		;restore YX
	exaf
	cmc			;complement hi/lo
	jmp	..tt
..norm: lxi	h,ColorScreen	;base of color area
	dad	b		;add box offset
	pop	b		;restore YX
	exaf
..tt:	jc	LoNib
; Check hi nibble
	mov	a,m		;get 2 color boxes
	ani	0f0h		;isolate left one
	cpi	GREY&0f0h	;gry=mirror
	jz	REFLECT
	exx
	cmp	c		;hi nib wall color	
	exx
	jz	WALLHIT
;must have hit another bolt or object
	jmp	HITCHK
; Check Lo Nibble
LoNib:
	mov	a,m		;add box offset
	ani	0fh		;isolate right one
	cpi	GREY&0fh	;gry=mirror
	jz	REFLECT
	exx
	cmp	b		;lo nib wall color
	exx
	jz	WALLHIT
;must have hit another bolt or object
	jmp	HITCHK
.sbttl	/Reflect the bolt/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Reflect the bolt
;_______________________________
;BC=yx, DE->vxy.len
REFLECT:
	ldax	d		;get vxy
	ani	0C0h		;check for any up/down
	jrz	..Ve		;right/left hit only verticals
	lhld	Temp		;get magic address
	res	5,h		;convert to normal
	mov	a,m		;get pixels of wall
	mvi	h,90h		;left nibble test
	bit	2,C		;if ((x.mod.8)<4)
	jrz	..test		; then left nibble
	mvi	h,09h		;right nibble test
..test: exaf			;save pixels
	lda	Flip
	ora	a
	jz	..on
	mvi	a,99h
	xra	h
	mov	h,a
..on:	exaf			;restore pixels
	ana	h		;look for non 60(vertical)
	jnz	..Ho
..Ve:	lxi	b,VerTab	;vertical table
	jmp	..Go
..Ho:	lxi	b,HorTab	;horizontal table
;bc=table de->vxy,hl->screen
..Go:	ldax	d		;get vxy
	ani	0f0h
	rrc
	rrc			;vxy*4
	mov	l,a
	mvi	h,0
	dad	b		;->RefTab[vxy]
	ldax	d		;->vxy.length
	ani	0fh		;keep length
	ora	m		;new vxy
	stax	d		;update vxy.len
	inx	d		;->px
	inx	h		;->offset x
	ldax	d		;get px
	add	m		;add offset
	mov	c,a		;save new x
	stax	d		;update px
	inx	d		;->py
	inx	h		;->offset y
	ldax	d		;get py
	add	m		;add offset
	mov	b,a		;save new y
	stax	d		;update py
;now write the new dot
	mov	h,b		;pY
	mov	l,c		;pX
	call	RELX
	mvi	m,80h		;write the new head
	sta	RFSND		;make ping sound
	RET

.define RE[vxy,xoffset,yoffset]=
[	.byte	vxy<4,xoffset,yoffset,0
]
VerTab: RE	0,0,0		;0 stoped
	RE	2,1,-4		;1 Left
	RE	1,-1,-4		;2 Right
	RE	0,0,0		;3
	RE	8,3,1		;4 Up-stop
	RE	6,1,-1		;5 UL->ur
	RE	5,-1,-1		;6 UR->ul
	RE	0,0,0		;7
	RE	4,3,-1		;8 Down-stop
	RE	10,1,1		;9 DL->dr
	RE	9,-1,1		;10 DR->dl
	RE	0,0,0		;11
	RE	0,0,0		;12
	RE	0,0,0		;13
	RE	0,0,0		;14
	RE	0,0,0		;15
; the horizontal version
HorTab: RE	0,0,0		;0 stoped
	RE	2,1,-4		;1 Left stop
	RE	1,-1,-4		;2 Right stop
	RE	0,0,0		;3
	RE	8,4,1		;4 Up
	RE	9,-1,1		;5 UL->dl
	RE	10,1,1		;6 UR->dr
	RE	0,0,0		;7
	RE	4,4,-1		;8 Down
	RE	5,-1,-1		;9 DL->ul
	RE	6,1,-1		;10 DR->ur
	RE	0,0,0		;11
	RE	0,0,0		;12
	RE	0,0,0		;13
	RE	0,0,0		;14
	RE	0,0,0		;15
.page
.sbttl	/Hit a Wall routine/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Blast the Wall
;_______________________________
;BC=yx, DE->vxy, hl->color
WallHit:
	ldax	d		;get vxy
	ani	0fh		;stop the vxy
	stax	d		;store 0.len
	xra	a		;0
	inx	d		;->px
	stax	d		;px=0
	inx	d		;->py
	stax	d		;py=0 (finished with DE)
; change color box to robot color
	bit	2,C		;left/right nibble bit(4)
	lxi	d,0ff0h		;left half mask
	jrz	..fix
	lxi	d,#0ff0h	;right mask
..fix:	lda	Flip
	ora	a
	jrz	..auk
	mov	a,d		;swap em
	mov	d,e
	mov	e,a
..auk:	mov	a,m		;get 2 color boxes
	ana	d		;mask valid part
	mov	d,a		;save
	lda	Rcolor		;get robot color
	ana	e		;isolate nibble
	ora	d		;combine nibbles
	mov	m,a		;store new color
;index the box's pixels = (Y&!3) (X&!3)
	mov	a,b		;pY
	ani	#3		;move to nearest multiple of 4
	mov	h,a
	mov	a,c		;pX
	ani	#3
	mov	l,a
	call	RELAnd
	xchg
	lxi	h,WallPts	;add 1 pt
	mov	a,m		;for hitting wall
	adi	1
	daa
	mov	m,a
	sta	WLSND		;make sound
	lxi	h,Cross
	jmp	Plot#
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Special Relative to Absolute
;_______________________________
;save all but hl,af
;HL=YX
RELAnd::
RELX:	push	b
	mvi	B,90H		;xor write
	call	RtoA#
	pop	b
	ret
.page
.sbttl	/Hit Check for objects/
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Find Out What Got hit
;_______________________________
; BC=YX,de->vxy
HITCHK:
	ldax	d		;get vxy
	ani	0fh		;stop it
	stax	d		;store 0,len
	mvi	a,MaxVec	;number of vectors to check
	lxi	x,Vectors	;->first vector
..LOOP:
	exaf			;save count
	bit	Move,V.Stat(x)	;check if moving
	jz	..next
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check Vector[ix] Against Bolt
;_______________________________
;NOTE: should mans bolt kill him?
;ix->object, BC=YX, a'=counter
	mov	a,c		;bolt X
	sub	P.X(x)		;object Y
	inr	a
;	mov	c,a		;save it
	jm	..next		;outside on left?
	cpi	10		;max width
	jrnc	..next		;ok in x
	mov	a,b		;now do y
	sub	P.Y(x)
	inr	a
	jm	..next
	cpi	30
	jnc	..next
;check with real pattern size
	mov	h,D.P.H(x)	;get pattern pointer
	mov	l,D.P.L(x)
	mov	e,m		;get address of pattern
	inx	h
	mov	d,m
	xchg			;hl->pattern
	mov	e,m		;get width in bytes of pattern
	inx	h
	mov	d,m		;get height
	bit	7,d		;check for DROP
	jz	..ok
	xchg			;special for otto drop
	dad	h
	dad	h
	dad	h		;drop/32
	sub	h		;adjust delta Y
	xchg
	inx	h		;now get real Y height
	mov	e,m
	inx	h
	mov	d,m
..ok:	inr	d		;adjust for 1 higher in Y
	inr	d
; now check if bolt y is in pattern
	cmp	d		;a still y delta
	jnc	..next
;now x NOT NEEDED ALL ARE 8 WIDE
;	mov	a,c		;restore delta
;	sub	P.X(x)
;	slar	e		;multiply X.size**NEW
;	slar	e		;by 8 cuz of 8 bits to byte
;	slar	e		;of pattern
;	inr	e		;add one for slop
;	cmp	e		;is in past right side?
;	jrnc	..next
; hit this vector, so set his inept bit
	set	Hit,V.STAT(x)
	set	INEPT,V.STAT(x) ;cause an explosion
	RET			;leave loop
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	End of Loop
;_______________________________
..next: lxi	d,VLEN		;distance to
	dadx	d		;next vector
..exit: exaf			;get counter
	dcr	a		;any more vectors left?
	jrnz	..LOOP		;if not,go check this one
	ret			;go do another bolt

; Pattern of wall
Cross:	.byte	1,4
	.byte	060h,0f0h,0f0h,060h

	.end
