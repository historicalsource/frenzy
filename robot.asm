B>type robot.asm

.title	"MOVE ROBOTS"
.sbttl	"FRENZY"
.ident	ROBOT
;-------------+
; robot mover |
;-------------+
.insert equs
.intern SETPAT
.extern SHOWO,V.ZERO,SHOWA,R.9D,J.WAIT,NEXT.J,ADDS,SETVXY
.extern R.9,D.TAB,SHOOT,IQ,RANDOM
;------------+
; initialize |
;------------+
;minwait=	40	;2/22/82
MinWait=	30		;Harder 3/12/82
FROBOT::call	V.ZERO		;get vector
	JC	JobDel#		;if non leave
	ldar
	rrc
	jrc	..2
	call	F1.TALK#
	jmpr	..1
..2:	call	F2.TALK#
..1:	mvi	P.X(x),146	;start pos
	mvi	P.Y(x),104
	lxi	h,R.LAY#
	mov	D.P.L(x),l
	mov	D.P.H(x),h
	mvi	c,0
	jmpr	RGO
ROBOT::
	call	V.ZERO		;get vector
	JC	JobDel#		;if non leave
	lxi	h,Robots
	inr	m		;inc number of robots
	mov	a,m
	sta	Rsaved		;save number of robots
	ldar
	ani	1
	jnz	SKEL#
; find a spot to put me
	call	InitPosition
	xra	a		;stop mode
	mvi	c,-1		;force on
	call	SETPAT		; set up vector
RGO:	mvi	TPRIME(x),2	;standard wait time
	mvi	TIME(x),1	;update
	mvi	V.STAT(x),86h	;write|move
	call	GetTimer#
	lda	Rwait		;initial hold off
	cpi	MinWait
	jrnc	..1		;safety 1st
	mvi	A,MinWait	;minimum wait
; initial wait period hl->timer
..1:	mov	b,a
	call	RANDOM		;slight randomness in
	ani	0F8h		;wake-up time
	rrc
	rrc
	rrc
	add	b
	mov	m,a
..wlp:	call	NEXT.J
	bit	INEPT,V.STAT(x)
	jrnz	..blam
	mov	a,m
	ora	a
	jrnz	..wlp
..blam:
	mvi	C,0		;set tracker=stop
;-----------------+
; robots job loop |
;-----------------+
; ix->vector
; hl->timer
SEEK:	lxi	y,Vectors	;mans vector
	push	b		;save tracker
; test if anything happened first??
	mov	a,P.X(y)	;man x
	sub	P.X(x)		;robot x
	mov	d,a		;save delta x
;calc x index
	lxi	B,0		;0 velocity in x
	jrz	..dx
	mvi	B,1		;-	"	in x
	jrc	..dx
	mvi	B,2		;+	"	in x
..dx:	mov	a,P.Y(y)	;man y
	ADI	2
	sub	P.Y(x)		;robot y
	mov	e,a		;save delta y
;calc y index
	jrz	..dy
	mvi	C,4		;-	"	in y
	jrc	..dy
	mvi	C,8		;+	"	in y
..dy:	mov	a,b		;add offsets
	add	c		;to from direction
	pop	b		;restore tracker
	call	SHOOT		;need hl->timer
	call	SETPAT		;does IQ
	call	NEXT.J
R.RET:: bit	INEPT,V.STAT(x)
	jz	SEEK
	jmpr	BLAM
;-----------------------------+
; change direction of robot
;	a=data, c=tracker [0=stop]
;-----------------------------+
SETPAT: push	h
	lxi	h,IqFlg
	bit	1,m		;stop moving
	jrz	..1
	xra	a
	jmpr	..2
..1:	ani	0Fh		;check for no moving
	jrz	..2
	bit	0,m		;no iq
	cz	IQ		;then check walls returns a
..2:	cmp	c		;if tracker and new direction
	jrz	..exit		;are the same then return
	mov	c,a		;update tracker
	call	SETVXY
	lxi	h,P.TAB		;index pattern table
	dad	d		;returned from setvxy
	mov	a,m		;get pattern address
	inx	h
	mov	h,m
	di
	mov	D.P.L(x),A	;set pattern
	mov	D.P.H(x),H
	ei
..exit: pop	h
	ret
;--------------+
; blow up time |
;--------------+
BLAM::	call	FreeTimer#
	push	x		;->vector
	call	SBLAM#
	pop	h		;->vector
	lxi	d,V.X		;hl=>v.x
	dad	d
	di
	mov	m,d		;d=0 v.x
	inx	h		;->p.x
	mov	a,m
	sui	4		;offset blast pattern
	mov	m,a
	inx	h		;->v.y
	mov	m,d		;d=0
	inx	h		;->p.y
	mov	a,m		;get position
	sui	6		;offset for large blast
	mov	m,a
	inx	h		;->d.p.l
	lxi	b,R.9		;blast pattern
	mov	m,c
	inx	h
	mov	m,b
	ei
	mvi	TIME(x),1
	mvi	TPRIME(x),1
	push	x		;->vector
	lxi	b,105H		;50
	call	ADDS
	lxi	h,Robots	;score bonus
	mov	a,m
	ora	a
	jz	XXX
	dcr	m		;one less robot
	sta	STIME		;new robot hold off
	jrnz	XXX		;if all killed then
	lda	Rsaved		;get original number of robots
SCLOP:	push	psw
	lxi	b,101H		;score 10 for each killed
	call	ADDS
	pop	psw
	dcr	a
	jrnz	SCLOP
; write bonus
	call	SHOWA
	.byte	0,96,213
	.asciz	"BONUS"
; show how much
	push	psw
	lda	Rsaved
	mov	b,a		;convert to BCD
	xra	a		;0
..:	ADI	1		;+1
	daa			;adjust
	djnz	..		;for number of robots
	rrc
	rrc
	rrc
	rrc
	mov	l,a
	ani	0F0H
	mov	h,a
	mvi	A,0FH
	ana	l
	mov	l,a
	pop	psw
	push	h		;put number on stack
	lxi	h,0
	dad	sp		;->number on stack
	exaf
	mvi	B,4
	call	SHOWO
	pop	h		;remove number from stack
XXX:	pop	x
	WAIT	30
..test: lxi	h,R.9D
	mov	a,O.P.L(x)	;see if on last pattern
	cmp	l
	jrnz	..no
	mov	a,O.P.H(x)
	cmp	h
	jrz	..done
..no:	call	NEXT.J
	jmpr	..test
..done: mvi	V.STAT(x),0	;free vector
	jmp	JobDel		;delete job
;~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Find a spot for this robot to start
;___________________________
InitPosition::
	call	RANDOM
..sl:	sui	24
	jrnc	..sl
	adi	24
	mvi	b,0
	mov	c,a
	lxi	h,Walls
	dad	b		;->walls array
	mov	a,m		;test if in use,exit or man
	ani	0F0h		;non wall bits
	jrz	..use
	mov	a,c
	inr	a
	jmpr	..sl
; fix up faster with linear probe?
..use:	set	InUse,m		;save our square
	lxi	h,R.Tab		;->starting squares
	dad	b
	dad	b
	mov	d,m		;get x position
	inx	h
	mov	e,m
	call	Rand27
	add	d
	mov	P.X(x),a	;set position
	call	Rand27
	add	e
	mov	P.Y(x),a
	ret
Rand27: push	d
	call	RANDOM
	pop	d
..:	sui	26
	jrnc	..
	adi	26
	ret
;--------------------------------
; ROBOT starting position table
X1	==	12
X2	==	X1+(40*1)
X3	==	X1+(40*2)
X4	==	X1+(40*3)
X5	==	X1+(40*4)
X6	==	X1+(40*5)
Y1	==	8
Y2	==	Y1+(48*1)
Y3	==	Y1+(48*2)
Y4	==	Y1+(48*3)
R.TAB:	.byte	X1,Y1
	.byte	X2,Y1
	.byte	X3,Y1
	.byte	X4,Y1
	.byte	X5,Y1
	.byte	X6,Y1

	.byte	X1,Y2
	.byte	X2,Y2
	.byte	X3,Y2
	.byte	X4,Y2
	.byte	X5,Y2
	.byte	X6,Y2

	.byte	X1,Y3
	.byte	X2,Y3
	.byte	X3,Y3
	.byte	X4,Y3
	.byte	X5,Y3
	.byte	X6,Y3

	.byte	X1,Y4
	.byte	X2,Y4
	.byte	X3,Y4
	.byte	X4,Y4
	.byte	X5,Y4
	.byte	X6,Y4
;----------------
; pattern table
;
.define PAT[P1]=[
.extern P1
	.word	P1]

P.TAB:	PAT	R.0
	PAT	R.1
	PAT	R.2
	PAT	R.3
	PAT	R.4
	PAT	R.5
	PAT	R.6
	PAT	R.7
	PAT	R.8

BYTE3:: .byte	0

	.end

