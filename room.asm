B>type room.asm

.title	"Draw Room and Set Pointers"
.sbttl	"FRENZY"
.ident	ROOM
;--------------------+
; room related stuff |
;--------------------+
.insert equs
.extern SHOWC,SHOWS,SHOWA,SHOWN,RtoA
.extern CREDS,C.WALLS,PLOT,RANDOM
; Equates
BDOWN	==	3
BUP	==	2
BRIGHT	==	1
BLEFT	==	0
ORWRITE ==	10H
.define XY[PX,PY]=[
	lxi	h,PY*256+PX]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on left
;_______________________________
RoomLeft::
	call	RINIT
	set	BLEFT,0+24(x)
	set	BLEFT,6+24(x)
	set	BLEFT,12+24(x)
	set	BLEFT,18+24(x)
	lhld	ManX
	mov	l,h		;get y
	mvi	h,240		;set x
	call	WallIndex#
	lxi	h,24
	dad	d
	set	BRIGHT,m
	jmp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on Right
;_______________________________
RoomRight::
	call	RINIT
	set	BRIGHT,5+24(x)
	set	BRIGHT,11+24(x)
	set	BRIGHT,17+24(x)
	set	BRIGHT,23+24(x)
	lhld	ManX
	mov	l,h		;get y
	mvi	h,16		;set x
	call	WallIndex#
	lxi	h,24
	dad	d
	set	BLEFT,m
	jmp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on Down
;_______________________________
RoomDown::
	call	RINIT
	set	BDOWN,18+24(x)
	set	BDOWN,19+24(x)
	set	BDOWN,20+24(x)
	set	BDOWN,21+24(x)
	set	BDOWN,22+24(x)
	set	BDOWN,23+24(x)
	lhld	ManX
	mov	h,l		;get x
	mvi	l,16		;set y
	call	WallIndex#
	lxi	h,24
	dad	d
	set	BUP,m
	jmp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show room with door on Up
;_______________________________
RoomUp::
	call	RINIT
	set	BUP,0+24(x)
	set	BUP,1+24(x)
	set	BUP,2+24(x)
	set	BUP,3+24(x)
	set	BUP,4+24(x)
	set	BUP,5+24(x)
	lhld	ManX
	mov	h,l		;get x
	mvi	l,180		;set y
	call	WallIndex#
	lxi	h,24
	dad	d
	set	BDOWN,m
	jmp	DoRo	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Show outline of room
;_______________________________
ROOM::	lxi	h,RoomCnt
	dcr	m
	call	RINIT
; generate walls bits
DoRo:	lxi	x,WALLS
	call	ROW
	call	ROW
	call	ROW
; draw walls
	call	RoomDraw
	call	C.WALLS		; color walls
	call	Wdot		;add white dots
	call	SHOWS
; show number of deaths left
SHOWD:: lda	PLAYER
	cpi	2
	XY	56,213
	jrnz	DPI
	mvi	L,232
DPI:	mvi	B,0
	call	RtoA
	xchg
	exaf
	lda	DEATHS
	mov	b,a
	exaf
	dcr	b
	jrz	SSE
DLP:	push	b
	mvi	C,80H		;man
	call	SHOWC
	inx	d
	exaf
	lda	Flip
	ora	a
	jrz	..
	dcx	d
	dcx	d
..:	exaf
	pop	b
	djnz	DLP
SSE:	lda	Demo		;if demo,show credits
	ora	a
	cnz	CREDS
	ret
;---------------------------+
; Generate 0-4 random walls |
;---------------------------+
ROW:	mvi	b,5
..lp:	push	b
	call	RANDOM
	lxi	b,..ret		;return address for all
	push	b		;do table call sort of
	ani	3
	jz	UP
	dcr	a
	jz	DOWN
	dcr	a
	jz	RIGHT
	jmp	LEFT
..ret:	pop	b		;move to next column
	inx	x
	djnz	..lp
	inx	x
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Wall setting routines
;_______________________________
DOWN:	set	BRIGHT,6(x)
	set	BLEFT,7(x)
	lda	SEED		;reflecto wall?
	rlc
	rnc
	set	BRIGHT,24+6(x)	;set reflecto
	set	BLEFT,24+7(x)
	ret
;
UP:	set	BRIGHT,0(x)
	set	BLEFT,1(x)
	lda	SEED
	rlc
	rnc
	set	BRIGHT,24+0(x)
	set	BLEFT,24+1(x)
	ret
;
RIGHT:	set	BDOWN,1(x)
	set	BUP,7(x)
	lda	SEED
	rlc
	rnc
	set	BDOWN,24+1(x)
	set	BUP,24+7(x)
	ret
;
LEFT:	set	BDOWN,0(x)
	set	BUP,6(x)
	lda	SEED
	rlc
	rnc
	set	BDOWN,24+0(x)
	set	BUP,24+6(x)
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Draw a Room
;_______________________________
RoomDraw:
	mvi	h,4
	lxi	x,walls
	lxi	b,(4<8)!(1<BUP)
..lp:	call	HORIZ
	mvi	a,48
	add	h
	mov	h,a
	djnz	..lp
	lxi	x,walls+(3*6)	; do last wall
	mvi	c,1<BDOWN
	call	HORIZ
	lxi	x,walls		; do verticals
	lxi	b,(6<8)!(1<BLEFT)
	mvi	L,8
..kp:	call	VERT
	mvi	a,40
	add	l
	mov	l,a
	djnz	..kp
	dcx	x		;do last vert wall
	mvi	c,1<BRight
	call	VERT
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Draw complete horizontal
;_______________________________
HORIZ:	push	b
	mvi	l,8
	mvi	b,6
..lp:	push	h
	push	b
	mov	a,24(x)		;check reflecto wall
	ana	c
	jrz	..nor		;0=non reflecto
	mov	a,0(x)
	ana	c
	jrz	..sq
	call	HWR
	jmpr	..open
..sq:	call	HWS
	jmpr	..open
..nor:	mov	a,0(x)
	ana	c
	jrz	..open
	call	HWB
..open: pop	b
	pop	h
	inx	x
	mvi	a,40
	add	l
	mov	l,a
	djnz	..lp
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~
; Draw complete Vertical
;__________________________
VERT:	push	b
	mvi	h,4
	mvi	b,4
..lp:	push	h
	push	b
	mov	a,24(x)		;check reflecto wall
	ana	c
	jrz	..nor		;0=non reflecto
	mov	a,0(x)
	ana	c
	jrz	..sq
	call	VWR
	jmpr	..open
..sq:	call	VWS
	jmpr	..open
..nor:	mov	a,0(x)
	ana	c
	jrz	..open
	call	VWB
..open: pop	b
	pop	h
	lxi	d,6
	dadx	d
	mvi	a,48
	add	h
	mov	h,a
	djnz	..lp
	lxi	d,-(6*4)+1
	dadx	d
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Horizontal wall of Crosses
;_______________________________
HWB::	mvi	B,11
Hlp:	push	b		;number of bricks to write
	push	h		;x and y relative addr
	call	RELOR		;convert coordinates
	lxi	h,CROSS		;brick pattern
	call	PLOT		;plot a brick
	pop	h
	pop	b
	mvi	A,4		;move to end of brick in x
	add	l		;to lay next one
	mov	l,a
	djnz	Hlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Horizontal wall of Squares
;_______________________________
HWS:	mvi	B,11
..Hlp:	push	b		;number of bricks to write
	push	h		;x and y relative addr
	call	RELOR		;convert coordinates
	lxi	h,CUBE		;brick pattern
	call	PLOT		;plot a brick
	pop	h
	pop	b
	mvi	A,4		;move to end of brick in x
	add	l		;to lay next one
	mov	l,a
	djnz	..Hlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Horizontal wall of Reflecto
;_______________________________
HWR:	push	h
	call	RELOR
	lxi	h,HSTART
	call	PLOT
	pop	h
	mvi	A,4		;move to end of brick in x
	add	l		;to lay next one
	mov	l,a
	mvi	B,9
..lp:	push	b		;number of bricks to write
	push	h		;x and y relative addr
	call	RELOR		;convert coordinates
	lxi	h,HBLOCK		;brick pattern
	call	PLOT		;plot a brick
	pop	h
	pop	b
	mvi	A,4		;move to end of brick in x
	add	l		;to lay next one
	mov	l,a
	djnz	..lp		;do another brick
	call	RELOR		;convert coordinates
	lxi	h,HEND
	jmp	PLOT
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vertical wall of Crosses
;_______________________________
VWB::	mvi	B,13
Vlp:	push	b		;number of bricks to write
	push	h		;x and y relative addr
	call	RELOR		;convert coordinates
	lxi	h,CROSS
	call	PLOT
	pop	h
	pop	b
	mvi	A,4		;move to end of brick in y
	add	h		;to lay next one
	mov	h,a
	djnz	Vlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vertical wall of Squares
;_______________________________
VWS:	mvi	B,13
..Vlp:	push	b		;number of bricks to write
	push	h		;x and y relative addr
	call	RELOR		;convert coordinates
	lxi	h,CUBE
	call	PLOT
	pop	h
	pop	b
	mvi	A,4		;move to end of brick in y
	add	h		;to lay next one
	mov	h,a
	djnz	..Vlp		;do another brick
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Vertical wall of Crosses
;_______________________________
VWR:	push	h
	call	RELOR
	lxi	h,VSTART
	call	PLOT
	pop	h
	mvi	A,4		;move to end of brick in y
	add	h		;to lay next one
	mov	h,a
	mvi	B,11
..lp:	push	b		;number of bricks to write
	push	h		;x and y relative addr
	call	RELOR		;convert coordinates
	lxi	h,VBLOCK
	call	PLOT
	pop	h
	pop	b
	mvi	A,4		;move to end of brick in y
	add	h		;to lay next one
	mov	h,a
	djnz	..lp		;do another brick
	call	RELOR
	lxi	h,VEND
	jmp	PLOT
;----------------------+
; relative to absolute |
;----------------------+
RELOR:	mvi	B,ORWRITE
	call	RtoA
	xchg
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Initialize walls arrays etc
;_______________________________
RINIT:	lhld	RoomX		;put room number
	shld	SEED		;in seed
;erase message area
	lda	FLIP
	ora	a
	jrnz	..flp
	lxi	h,10+211*Hsize+Screen	;modify for upside down??
	jmpr	..Nor
..flp:	lxi	h,Screen+10+2*Hsize
..Nor:	lxi	d,Hsize-12
	xra	a
	mvi	C,12		;for 12 lines
..JEL:	mvi	B,12		;erase 12 bytes
..MEL:	mov	m,a
	inx	h
	djnz	..MEL
	dad	d
	dcr	c
	jrnz	..JEL
; initialize walls array
	lxi	b,4*6*2
	lxi	d,WALLS
	lxi	h,R.DATA
	ldir
;generate doors - TOP
	lxi	x,Walls
	lhld	RoomX		;get coords
	mov	a,l		;get y
	ani	3
	mov	e,a
	mvi	d,0
	mov	h,d
	mov	l,e		;1
	dad	h		;2
	dad	d		;3
	dad	h
	xchg
	dadx	d		;6*
	RES	BLEFT,0(x)	;set door bit
;right
	lxi	x,Walls
	lhld	RoomX		;get coords
	mov	a,l		;get x
	inr	a
	ani	3
	mov	e,a
	mvi	d,0
	mov	h,d
	mov	l,e		;1
	dad	h		;2
	dad	d		;3
	dad	h
	xchg
	dadx	d		;6*
	RES	BRIGHT,5(x)	;set door bit
;top
	lxi	x,Walls
	lhld	RoomX		;get coords
	mov	a,h		;get y
	ani	3
	inr	a
	mov	e,a
	mvi	d,0
	dadx	d
	RES	BUP,0(x)	;set door bit
;bottom
	lxi	x,Walls
	lhld	RoomX		;get coords
	mov	a,h		;get y
	inr	a
	ani	3
	inr	a
	mov	e,a
	mvi	d,0
	dadx	d
	RES	BDOWN,18(x)	;set door bit
;inc number of rooms seen
	lxi	h,RoomCnt
	inr	m		;inc room count
	mov	a,m
	cpi	32+1
	jrc	..rm
	cpi	-1
	jrz	..rm
	mvi	m,19		;3 rooms of white hell
..rm:	mov	a,m
	ora	a
	jrz	..skw
	ani	3		;test for special room
	cz	S.ROOM#
..skw:	lxi	x,Walls		;everyone needs this
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Put white dot around edge
;_______________________________
Wdot:	lxi	h,D.Table	;dot table
..loop: mov	a,m		;x
	ora	a
	rz
	mov	c,a		;set X
	inx	h
	mov	b,m		;set Y
	inx	h
	push	h
	call	Cdot
	pop	h	
	jmp	..loop
; change dot at bc to white
Cdot:	push	b		;save YX
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
..tt:
; change color box to grey
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
	lda	Dcolor		;get dot color
	ana	e		;isolate nibble
	ora	d		;combine nibbles
	mov	m,a		;store new color
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; initial room data
;__________	d.u.r.l
R.DATA: .byte	5,4,4,4,4,6
	.byte	1,0,0,0,0,2
	.byte	1,0,0,0,0,2
	.byte	9,8,8,8,8,10
	.byte	0,0,0,0,0,0
	.byte	0,0,0,0,0,0
	.byte	0,0,0,0,0,0
	.byte	0,0,0,0,0,0
; table of dot positions
D.Table:
	.byte	8,4,8,52,8,100,8,148,8,196
	.byte	248,4,248,52,248,100,248,148,248,196
	.byte	48,4,88,4,128,4,168,4,208,4
	.byte	48,196,88,196,128,196,168,196,208,196
	.byte	0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; patterns for walls
;__________________________________
CUBE:	.byte	1,4
	.byte	0F0h,090h,090h,0F0h
CROSS:	.byte	1,4
	.byte	060h,0F0h,0F0h,060h
Vblock: .byte	1,4
	.byte	060h,060h,060h,060h
VSTART: .byte	1,4
	.byte	000h,060h,060h,060h
VEND:	.byte	1,4
	.byte	060h,060h,060h,000h
HBLOCK: .byte	1,4
	.byte	000h,0F0h,0F0h,000h
HSTART: .byte	1,4
	.byte	000h,070h,070h,000h
HEND:	.byte	1,4
	.byte	000h,0E0h,0E0h,000h

	.end
