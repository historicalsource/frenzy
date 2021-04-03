B>type man.asm

.title	"MOVE MAN"
.sbttl	"FRENZY"
.ident MAN
;~~~~~~~~~~~~
; man mover
;____________
.insert EQUS
.intern V.ZERO,M.INIT,D.TAB
.extern SETVXY,WallIndex,Man.Next
ManP	=	6		;bit number in walls
SHOOT	==	4		;shoot button bit
DOWN	==	3
UP	==	2
RIGHT	==	1
LEFT	==	0
;~~~~~~~~~~~~~
; initialize
;_____________
MAN::	call	M.INIT
	mvi	V.STAT(x),(1<InUse)!(1<Color)!(1<Move)!(1<Write)
	lxi	b,-1		;tracker
	call	GetTimer#
	xchg
;~~~~~~~~~~~~~~~~
; mans job loop
;________________
;bc=tracker
;de->timer
;ix->vector
C.LOOP: call	Man.Next
	bit	INEPT,V.STAT(x) ; check if alive
	jnz	DEAD
	lda	Demo		;check for demo
	ora	a
	jrz	..real
;automatic demo mode
	ldax	d
	ora	a
	jrz	..new
	mov	a,c
	jmpr	ARGH
..new:	lhld	DemoPtr
	mov	a,m
	inx	h
	shld	DemoPtr
	bit	7,A
	jrz	..go
	res	7,A
	stax	d		;start timer
	jmpr	C.LOOP
..real: call	S.STICK#
..go:	bit	SHOOT,A		; if(shoot) fire
	jrnz	TRY.F
ARGH:	ani	0FH		;mask off DURL bits
	call	IQ#
	cmp	c		;compare to tracker
	cnz	CHANGE		;if changed update vector
	jmpr	C.LOOP
;~~~~~~~~~~~~~~
; try to fire
;______________
TRY.F:	mov	b,a		;save control
	ldax	d		;get timer
	ora	a
	jrnz	..0
	xra	a
	lxi	y,BUL1		;bolt one available?
	ora	0(y)		;check Vxy.len
	jrz	FIRE		;then fire
	lxi	y,BUL1+Blength	;bolt 2 available?
	xra	a
	ora	0(y)
	jrz	FIRE
..0:	mvi	a,0
	jmpr	ARGH		;none available=loop
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	shoot plasma bolt
;_______________________________
FIRE:	mov	a,b		;last control
	ani	0FH		; look at direction
	jz	C.LOOP		;COULD DEFAULT TO LAST DIR
	push	d		;save ->timer
	call	SFIRE#
	mov	c,a
	mvi	B,0		;bc=direction bits DURL
	mov	d,b		;zero d too
	lxi	h,D.TAB		;->direction table
	dad	b		;->offset for direction
	mov	e,m
	lxi	h,SR.TAB	;->shoot table
	dad	d		;2 per entry
	dad	d		;4
	dad	d		;6
	mvi	V.X(x),0	;set velocitys to 0
	mvi	V.Y(x),0
	mov	a,m		;get shoot animation table
	inx	h
	di
	mov	D.P.L(x),A
	mov	a,m
	inx	h
	mov	D.P.H(x),A
	ei
	mvi	TIME(x),1
	pop	d		;restore ->timer
	xchg
	mvi	m,2		;wait for 2 ints
..wt:	call	Man.Next	;wait for pattern to be written
	mov	a,m		;get the timer
	ora	a
	jrnz	..wt
	xchg			;hl->offsets
	push	d		;save ->timer
	mov	b,m		;x offset from man
	inx	h
	mov	c,m		;y offset from man
	inx	h
	mov	a,m		;vx.vy for bullet
	ori	6		;length of bolt
	mov	d,a		;vxy.len
	mov	a,P.X(x)	;load mans x position
	add	b		;add x offset
	mov	e,a		;px
	mov	a,P.Y(x)	;load mans y position
	add	c		;add y offset
	mov	c,a		;py
	push	Y
	pop	h
	mvi	b,BLength
	xra	a
..zap:	mov	m,a
	inx	h
	djnz	..zap
	di
	mov	0(y),D		;head vx.vy
	mov	1(y),E		;set px	 py for head
	mov	2(y),C
	mov	3(y),E		;set px	 py for tail
	mov	4(y),C
	ei
	mvi	C,00		;set automatic fire
	pop	h		;->timer
	mvi	m,4		;wait for exit from gun
..wlp:	call	Man.Next
	mov	a,m		;test timer
	ora	a
	jrnz	..wlp
	mvi	m,13		;in the timer
	xchg			;put -> back in de
	jmp	C.LOOP		;goto control loop
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; change direction of man
;  a=data, c=tracker [0=stop]
;_______________________________
CHANGE: ani	0FH
;changed direction and moving
CDIR:	push	d		;save timer->
	call	SetVXY		;updates c:=tracker
	lxi	h,P.TAB
	dad	d		;offset calced in setvxy
	mov	a,m		;dpl
	inx	h
	mov	h,m
	di
	mov	D.P.L(x),A
	mov	D.P.H(x),H
	ei
	pop	d		;restore timer->
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Kill Man job off
;_______________________________
DEAD:	call	SFRY#
	mvi	A,10H		;electrocute
	call	CDIR
	xchg
	mvi	m,150		;electrocution timer
..wlp:	call	Man.Next
	lda	Mcolor		;get man color
	adi	55h		;change for explosion
	ori	88h
	sta	Mcolor
	mov	a,m
	ora	a
	jrnz	..wlp
	mvi	V.STAT(x),(1<InUse)!(1<BLANK)!(1<ERASE)
..lp:	call	Man.Next
	bit	ERASE,V.STAT(x)
	jrnz	..lp
	mvi	m,30
..wt:	call	Man.Next
	mov	a,m
	ora	a
	jrnz	..wt
	mvi	V.STAT(x),0	;free the vector
	xra	a
	sta	Man.Alt		;don't do me anymore
..end:	call	Man.Next
	jmp	..end		;just in case
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Start a man vector
;_______________________________
M.INIT:
	call	V.ZERO		;ix->vector
; man must be first vector
	lda	PLAYER
	cpi	1
	mvi	a,M1color
	jrz	..s
	mvi	a,M2color
..s:	sta	Mcolor		; set color of man
	lhld	ManX		;gets x and y position
	mov	P.X(x),L	;set x
	mov	P.Y(x),H	;set y
	mov	a,l		;swap h:l
	mov	l,h
	mov	h,a
	call	WallIndex	;see what room # im in
	xchg
	set	ManP,m		;warns robots to stay away
	xra	a		;stand still
	call	CHANGE		;set up vector
	mvi	TPRIME(x),1
	mvi	TIME(x),1
	mvi	a,0aah		;force man to plot
	sta	IntTyp
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; find and zero a vector
;_______________________________
V.ZERO: lxi	h,Vectors	;->vector area
	lxi	d,VLEN		;vector length
	mvi	b,MaxVec	;# of vectors
..test: bit	InUse,M		;check if in use
	jrz	..ok
	dad	d
	djnz	..test
	stc			;error return
	ret
..ok:	push	h		;->your new vector
	lxi	b,VLEN		;# of bytes to zero
	call	Zap#		;zero the vector
	pop	x		;save vector pointer in x
	set	InUse,V.STAT(x)
	ora	a		;normal return
	ret
;~~~~~~~~~~~~~~~~~~
; direction table
;__________________
D.TAB:	.byte	0		;no move
	.byte	6*2		;left
	.byte	2*2		;right
	.byte	0
	.byte	8*2		;up
	.byte	7*2		;up,left
	.byte	1*2		;up,right
	.byte	8*2		;up default
	.byte	4*2		;down
	.byte	5*2		;down,left
	.byte	3*2		;down,right
	.byte	4*2		;down default
	.byte	0
	.byte	6*2		;left default
	.byte	2*2		;right default
	.byte	0
	.byte	9*2		;explode
;~~~~~~~~~~~~
; move table
;		x ,y ,animation-table
.define PAT[ADDR]=[
.extern ADDR
	.word	ADDR
]
P.TAB:	PAT	M.0
	PAT	M.1
	PAT	M.2
	PAT	M.3
	PAT	M.4
	PAT	M.5
	PAT	M.6
	PAT	M.7
	PAT	M.8
	PAT	M.9
;~~~~~~~~~~~~~~~~~~~~~~
;	Shoot table
;______________________
.define SS[Xo,Yo,Pat,VXY]=[
.extern Pat
	.word	Pat
	.byte	Xo,Yo,VXY<4,0
]
SR.TAB: SS	0,0,MS.0,0
	SS	8,2,MS.1,6
	SS	8,3,MS.2,2
	SS	7,7,MS.3,10
	SS	6,8,MS.4,8
	SS	-1,7,MS.5,9
	SS	-1,3,MS.6,1
	SS	-1,-1,MS.7,5
	SS	7,1,MS.8,4

	.end
