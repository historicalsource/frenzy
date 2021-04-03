B>type super.asm

.title	"SUPER-ROBOT"
.sbttl	"FRENZY"
.ident SUPER
;-------------+
; super robot |
;-------------+
.insert EQUS
.intern SETVXY
.extern NEXT.J,J.WAIT,D.TAB,V.ZERO,SR.0
Down=	3
Up=	2
Right=	1
Left=	0
;-------------
; Initialize
;-------------
SUPER::
	xra	a
	sta	CACKLE+1	;otto death flag
	lhld	ManX		;set position
	mov	a,l
	cpi	32
	jrnc	..r
	mvi	L,2
	jmpr	..y
..r:	cpi	240
	jrc	..y
	mvi	L,248
..y:	mov	a,h
	cpi	180
	jrc	..t
	mvi	H,160
..T:	shld	SSpos
	lda	Rsaved		; calc time til start
	mov	b,a
	lda	Rwait
	rrc
	rrc
	ani	7
	add	B
	sta	STIME
	mvi	e,0		;speed=1
; wait for stime seconds
..LOOP: WAIT	40
	lxi	h,STIME
	dcr	m
	jrnz	..LOOP
	lhld	SSpos		;super start pos
	mvi	a,30
	sta	KWait
	jmpr	INIT
;~~~~~~~~~~~~~~~~~~~~~~~
; Moms own SUPER Ottos
;_______________________
;de=yx to start
Klutz:: lxi	d,(84<8)!128
MSUPER::
	xchg			;get hl=YX
	lxi	d,1		;sportingly fast ottos
; initialize, e=speed
INIT:	push	d
	PUSH	H
	call	V.ZERO		; zap vector
	POP	H
	pop	d
	jc	JobDel#		;if none available forget it
	mov	a,e		;if faster speed no talk
	ora	a
	jrnz	REDO		;go fast
	PUSH	D
	PUSH	H
	call	S.TALK#
	POP	B
	POP	D
	WAIT	60
	mov	h,b
	mov	l,c		;start position
REDO:	mov	P.X(x),L	;set pos
	mov	P.Y(x),H
	xra	a
	mov	V.X(x),a
	mov	V.Y(x),a
	lxi	h,SR.0
	mov	D.P.L(x),L
	mov	D.P.H(x),H
	mvi	TIME(x),1
	mvi	TPRIME(x),2	;slower than normal
	mvi	d,0		;number of hits taken
	mvi	V.STAT(x),(1<InUse)!(1<Move)!(1<Write)
	xra	a
	call	SETDIR
	WAIT	60
	res	HIT,V.STAT(x)
;------------------------+
; super robot's job loop |
;------------------------+
SEEK:	lxi	y,Vectors	; mans vector
	push	D
;calc delta x => e
	mov	a,P.X(y)	;man x
	sub	P.X(x)		;robot x
;calc x index
	mvi	B,0		;0 velocity in x
	jrz	X.D
	mvi	B,1<RIGHT	;+ vel in x
	jrnc	X.D
	mvi	B,1<LEFT	;- vel in x
	neg
;calc delta y => d
X.D:	mov	d,a		;save |delta X|
	mov	a,P.Y(y)	;mans Y
	add	e		;drift down with speed
	mov	e,d		;save delta in right place
	sui	1
	cpi	175+1
	jc	..ok		;adjust mans x
	mvi	a,175
..ok:	sub	P.Y(x)
;calc y index
	mvi	C,0		;0 velocity in y
	jrz	Y.D
	mvi	C,1<DOWN	;+ vel in y
	jrnc	Y.D
	mvi	C,1<UP		;- vel in y
	neg
Y.D:	mov	d,a		;save abs(delta Y)
	mov	a,b		;add offsets
	add	c		;to from direction
	mov	b,d		;bc=de
	mov	c,e
	pop	D		;speed
	call	SETDIR
	bit	HIT,V.STAT(x)	;check for hits
	jrz	..wait
	res	HIT,V.STAT(x)	;reset hit bit
	call	SBLAM#		;hit sound
	inr	d		;number of hits taken
	push	d
; set new pattern
	lxi	h,SR.1#
	dcr	d
	jz	..stdp
	lxi	h,SR.2#
..stdp: mov	D.P.L(x),L
	mov	D.P.H(x),H
	mvi	TIME(x),1
	lxi	b,102h		;50pts
	call	ADDS#
	pop	d
	mov	a,d		;check hits
	cpi	3		;if 3 then DIE sucker
	jrz	DIE
..wait: call	NEXT.J
	jmpr	SEEK
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Otto Deflates
;_______________________________
DIE:	xra	a
	mov	V.X(x),a
	mov	V.Y(x),a
	cma
	sta	CACKLE+1	;otto death flag
	call	SD.TALK#
	lxi	h,SR.3#
	mov	D.P.L(x),L
	mov	D.P.H(x),H
	mvi	TPRIME(x),4	;real slow
	WAIT	60
	mvi	V.STAT(x),(1<InUse)!(1<Erase)
	WAIT	10
; start a new otto
	mov	a,e
	cpi	7
	jrnc	..n
	inr	e		;up the speed
..n:	lhld	SSpos
	jmp	REDO
;-----------------------------
; change direction of robot
; a=durl, e=speed
;-----------------------------
SETDIR: ani	0FH		; SUPER ROBOTS VERSION
	jnz	..nor
	lxi	b,0
	jmp	SETV
..nor:	PUSH	B		;save deltas
	EXAF			;save durl
;get speed numbers
	lxi	h,SpeedTab
	mvi	B,0
	mov	c,e
	dad	b
	dad	b
	mov	a,m
	mov	TPRIME(x),a
	inx	h
	mov	a,m		;speed
; now set vel
	POP	B		;delta yx
	cmp	b		;is vy<|delta|
	jrnc	..sy
	mov	b,a		;save smaller
..sy:	cmp	c		;is vx<delta
	jrnc	..sx
	mov	c,a		;save smaller
..sx:	EXAF			;get durl
	bit	up,a
	jrz	..dx
	EXAF
	mov	a,b
	neg			;vel=-vel
	mov	b,a
	EXAF
..dx:	bit	left,a
	jrz	..sv
	EXAF
	mov	a,c
	neg			;vel=-vel
	mov	c,a
	EXAF
..sv:
SETV:	mov	V.X(x),c
	mov	V.Y(x),b
	ret

; normal robot version
SETVXY: mov	c,a		;update tracker
	mvi	B,0
	lxi	h,D.TAB		;convert direction to offset
	dad	b
	mov	e,m		;load offset
	mov	d,b
	lxi	h,M.TAB		;index move table
	dad	d
	mov	a,m		;get vx
	mov	V.X(x),a
	inx	h
	mov	A,m		;get vy
	mov	V.Y(x),a
	ret
;----------------------
;  move table
;  x,y
M.TAB:	.byte	0,0
	.byte	1,-1
	.byte	1,0
	.byte	1,1
	.byte	0,1
	.byte	-1,1
	.byte	-1,0
	.byte	-1,-1
	.byte	0,-1
	.byte	0,0

.define ST[Tprime,Vel]=
[	.byte	Tprime,Vel
]
SpeedTab:
	ST	3,1
	ST	1,1
	ST	1,3
	ST	1,4
	ST	1,6
	ST	1,8
	ST	1,10
	ST	1,12

	.end
