B>type color.asm

.title	"Color Subroutines"
.sbttl	"FRENZY"
.ident COLOR
;---------------------------+
; color related subroutines |
;---------------------------+
.insert EQUS
.intern C.GO,C.L1,C.L2,C.LI,C.DIPS
.intern C.HIGH,C.WALLS,C.BOOKS
.intern C.MOVE
.extern ScorePtr
.extern J.WAIT
; equates
BRIGHT	==	88H
BLUE	==	44H
GREEN	==	22H
RED	==	11H
WHITE	==	77H
PURPLE	==	RED+BLUE
CYAN	==	BLUE+GREEN
YELLOW	==	RED+GREEN
; macros
.define LINES[LINE1,LINE2,COLOR]=[
	call	C.BOX
	.word	(LINE1*8)
	.byte	(LINE2-LINE1)/4
	.byte	32
	.byte	COLOR
]
.define BOX[X,Y,LINE2,WIDTH,COLOR]=[
	call	C.BOX
	.word	X+(Y*8)
	.byte	(LINE2-Y)/4
	.byte	WIDTH
	.byte	COLOR
]
;
; setup colors for game over / high scores
;
C.GO:	LINES	0,40,BRIGHT+RED
	LINES	40,56,Yellow
	LINES	56,60,77H
	BOX	0,60,184,10,GREEN
	BOX	10,60,184,8,RED
	BOX	17,60,184,15,Yellow
	LINES	184,224,077H
C.INFO: BOX	0,208,224,10,M1color
	BOX	22,208,224,10,M2color
	ret
; colors for title
C.TITLE::
	LINES	0,76,BRIGHT+RED
	LINES	76,224,BRIGHT+Yellow
	LINES	188,204,BLUE
	ret
; white screen for diag displays
C.DIPS:
	LINES	0,224,0FFH
	ret
;
; setup colors for insert coin
;
C.LI:	LINES	188,204,Yellow
	ret
;
; setup colors for press 1 or 2 player
;
C.L1:
C.L2:	LINES	188,204,Cyan
	ret
;
; setup colors for congratulations
;
C.HIGH: LINES	0,32,BRIGHT+Yellow
	LINES	32,96,Cyan
	LINES	96,112,0FFH
	LINES	112,224,BRIGHT+GREEN
	jmp	C.INFO
;
; setup colors for book-keeping show
;
C.BOOKS: LINES	0,188,BRIGHT+BLUE
	LINES	188,224,BRIGHT+GREEN
	ret
; colors for moveing room
C.MOVE: LINES	0,208,Purple
	ret
;-----------------------------
; fill color ram with a value
; inline parms:
; word 1:start address
; byte 2:number of lines
; byte 3:width in bytes
; byte 4:color fill value
; uses flip to determine direction
;-----------------------------
C.BOX:	pop	h		;get parameters address
	mov	e,m		;get start address
	inx	h
	mov	d,m
	inx	h
	push	h
; convert to offset
	lda	Flip
	ora	a
	jrnz	Up
Down:	lxi	h,ColorScreen
	dad	d
	jmpr	Brk
Up:	lxi	h,EndColor
	dsbc	d
Brk:	xchg
	pop	h
	mov	c,m		;number of lines
	inx	h
	exaf
	mov	a,m		;get width
	inx	h
	exaf
	ora	a		;test flipped=nz
Normal: mov	a,m		;get color
	inx	h
	push	h		;new return address
	xchg
	jrnz	Fli
	lxi	d,32		;# of bytes = x width
..y:	exaf
	mov	b,a		;put copy of width in b
	exaf
	push	h
..x:	mov	m,a		;put color into ram
	inx	h
	djnz	..x
	pop	h
	dad	d		;goto next line down
	dcr	c
	jrnz	..y
	ret
Fli: lxi	d,-32		;# of bytes = x
..y:	exaf
	mov	b,a		;put copy of width in b
	exaf
	push	h
..x:	mov	m,a		;put color into ram
	dcx	h
	djnz	..x
	pop	h
	dad	d		;goto next line down
	dcr	c
	jrnz	..y
	ret
;
; color walls of room
;
C.WALLS:
	LINES	208,224,077H
	call	C.INFO
	lxi	h,R.table	;percentage table
	lxi	b,RE.len	;length of robot table entry
	lda	RoomCnt		;total rooms travelled
	exaf
R.loop: exaf
	cmp	m
	jrc	R.set
	exaf
	dad	b
	mov	a,m
	ora	a
	jrnz	R.loop
; HL -> number of rooms to be travelled before using this mode
;	# of robot bolts,wait,robot color,wall color
R.set:	inx	h
	mov	a,m		;set total number of robot bolts
	inx	h
	sta	Rbolts
	mov	a,m		;set recharge time
	inx	h
	sta	Rwait
	mov	a,m		;robot color
	inx	h
	mov	c,a
	sta	Rcolor
	mov	a,m
	inx	h
	sta	Dcolor		;set Dotted wall color
	mov	a,m
	inx	h
	sta	Wcolor		;set wall color
	mov	a,m
	sta	Wpoint		;#point for wall hit
;now go color walls C=robot color
	lda	Flip
	ora	a
	lxi	h,ColorScreen
	lxi	x,ScreenRAM
	jrz	Ok
	lxi	h,ColorScreen+4*32
	lxi	x,ScreenRAM+16*Hsize
Ok:	mvi	A,208/4		;number of lines of room
..y:	exaf
	mvi	B,Hsize
..x:	mov	a,0(x)		;get screen
	xra	Hsize(x)
	ora	Hsize(x)
;nibble results 0=no wall, 9=cross, others=reflecto
	mov	d,a		;save
	ani	0fh		;isolate lower nibble
	jrnz	..lr
	mov	a,c
	jmpr	..LOW	
..lr:	cpi	0fh
	jrnz	..gry
	xra	0(x)
	ani	0fh
	jrnz	..c1
	lda	Dcolor
	jmpr	..LOW
..c1:	cpi	0Fh
	jrz	..gry
	lda	Wcolor		;get wall color
	jmpr	..LOW
..gry:	mvi	a,WHITE
..LOW:	ani	0fh
	mov	e,a		;save lower
	mov	a,d		;get top nibble
	ani	0f0h		;isolate lower nibble
	jrnz	..tr
	mov	a,c
	jmpr	..top	
..tr:	cpi	0f0h
	jrnz	..tig
	xra	0(x)
	ani	0f0h
	jrnz	..c2
	lda	Dcolor
	jmpr	..top
..c2:	cpi	0F0h
	jrz	..tig
	lda	Wcolor		;get wall color
	jmpr	..top
..tig:	mvi	a,WHITE
..TOP:	ani	0F0h
	ora	e		;or in lower
	mov	m,A		;write to colorRAM
	inx	h
	inx	x
	djnz	..x
	lxi	d,Hsize*3
	dadx	d
	exaf
	dcr	a
	jrnz	..y
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~
; un-color man as he moves
;___________________________
UNCMAN::
	LXI	H,VECTORS
	bit	BLANK,M
	rz
	res	BLANK,M
;restore old area of man
	lhld	Caddr
	lxi	d,Csave		;save area
	lxi	b,Hsize-1	;move to next line
	mvi	A,5		;is 5 x 4 high
..Ylp:	exaf
	ldax	d		;get old
	inx	d		;->next
	mov	m,a		;store back to color ram
	inx	h		;->next door loc
	ldax	d		;get another old one
	inx	d		;->next old line
	mov	m,a		;store to color ram
	dad	b		;->next line down in color ram
	exaf			;get counter
	dcr	a		;one less y line to do
	jnz	..Ylp
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; color man as he moves
;_______________________________
COLMAN::
	SET	BLANK,M
	lxi	d,P.X		;get to px
	dad	d		;->p.x.h
	mov	e,m		;x position
	inx	h		;->v.y
	inx	h		;->p.y
	lda	Flip
	ora	a		;test for flip screen
	mov	a,m		;y position
	jrz	..ok
	neg
	ADI	208		;index screen
	exaf
	mvi	A,247
	sub	e
	mov	e,a
	exaf
..ok:	srlr	A
	srlr	A
	mov	h,a
	mov	l,e
	srlr	H
	rarr	L
	srlr	H
	rarr	L
	srlr	H
	rarr	L
	lxi	b,ColorScreen
	dad	b
; save/write box to screen
	shld	Caddr		;save address of box
	lda	Mcolor		;get player color
	mov	c,a		;save new color
	lxi	d,Csave
	mvi	a,5		;number of bytes high
..Ylp:	exaf
	mov	a,m		;get current data
	stax	d		;save
	inx	d
	mov	m,c		;write new color
	inx	h
	mov	a,m		;get current data
	stax	d		;save
	inx	d
	mov	m,c		;write new color
	mov	a,c		;save color
	lxi	b,Hsize-1
	dad	b		;->next line
	mov	c,a		;restore color
	exaf
	dcr	a
	jnz	..Ylp
	lhld	V.PTR
	ret

;THIS SHOULD BE IN PLAY
; Robot Initializer Table
;		xx99xx,#	,0 or 1,bolt holdoff,color
.define RE[Room,Bolts,Wait,RCol,Dcol,Walls,Wp]=[
	.byte	Room,Bolts,Wait
	.byte	RCol,Dcol,Walls,Wp
]
;
BR=Bright
R.table: RE	01,0,90,Yellow,		Blue,	Purple,1
RE.len	== .-R.table
	RE	03,1,90,BR+Red,		Blue,	Purple, 1
	RE	05,2,75,Cyan,		Blue,	Purple, 1
	RE	07,3,60,BR+Green,	Yellow, BR+Red, 2
	RE	09,4,45,BR+Blue,	Yellow, BR+Red, 2
	RE	15,5,40,Purple,		Yellow, BR+Red, 2
	RE	16,3,25,BR+Green,	Purple, Blue,	3
	RE	17,4,20,Blue,		Yellow, Green,	4
	RE	21,5,15,Purple,		Yellow, Green,	4
	RE	23,5,45,BR+PURPLE,	Blue,	White,	4
	RE	24,2,15,Cyan,		Blue,	Green,	4
	RE	25,3,10,BR+Green,	Yellow, Blue,	3
	RE	27,4,05,Blue,		Purple, BR+Red, 2
	RE	30,5,05,Purple,		Cyan,	BR+Red, 2
	RE	00,5,05,Yellow,		Blue,	Cyan,	5

	.end

