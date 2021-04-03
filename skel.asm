B>type skel.asm

.title	"Skeletons"
.sbttl	"FRENZY"
.ident	SKEL
;-------------+
; robot mover |
;-------------+
.insert equs
.extern SHOWO,V.ZERO,SHOWA,R.9D,J.WAIT,NEXT.J,ADDS,SETVXY
.extern R.9,D.TAB,IQ,RANDOM
;------------+
; initialize |
;------------+
;MinWait=	45
MinWait=	35		;harder 3/12/82
SKEL::
;	lxi	h,Robots	;NOW DONE IN ROBOT-3/12/82
;	inr	m		;inc number of robots
;	mov	a,m
;	sta	Rsaved		;save number of robots
;	call	V.ZERO		;get vector
;	JC	JobDel#		;if non leave
; find a spot to put me
	call	InitPosition#
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
	mvi	A,MinWait		;minimum wait
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
;------------------
; Skel job loop
;------------------
; ix->vector
; hl->timer
SEEK:	lxi	y,Vectors	;mans vector
	push	b		;save tracker
; test if anything happened first??
	mov	a,P.X(y)	;man x
	SUI	1
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
	push	h
	ani	0FH		;if tracker non-0
	jrz	..ud
	lxi	h,IqFlg
	bit	1,m		;stop moving
	jrz	..1
	xra	a
	jmpr	..ud
..1:	bit	0,m		;no iq
	cz	IQ		;then check walls returns a
	bit	0,a
	jrnz	..go
	bit	1,a
	jrz	..ud
..go:	ani	3		;go rl first	
..ud:	cmp	c		;if tracker and new direction
	pop	h
	jrz	..sl		;are the same then return
	mov	c,a		;update tracker
	call	SETPAT		;does IQ
..sl:	call	NEXT.J
R.RET:	bit	INEPT,V.STAT(x)
	jz	SEEK
	jmp	BLAM#
;-----------------------------+
; change direction of robot
;	a=data, c=tracker [0=stop]
;-----------------------------+
SETPAT: push	h
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
;----------------
; pattern table
;
P.TAB:	.word	S.0#
	.word	S.2#
	.word	S.2
	.word	S.2
	.word	S.4#
	.word	S.6#
	.word	S.6
	.word	S.6
	.word	S.8#
;---------------------------------------
; if (a bolt is available) then
; if (it is possible to shoot at the man)
;	Shoot;
;---------------------------------------
; a=DURL to man
; hl->timer
SHOOT:
	push	h		;timer
	push	b		;tracker
	push	psw		;DURL
	mov	c,a		;save DURL
	mov	a,m		;check timer
	ora	a
	jrnz	..exit
	lda	IqFlg
	bit	2,a
	jrnz	..exit
; check if bolt available
	lda	Rbolts		;check if shooting
	ora	a
	jrz	..exit
	mov	b,a		;number of bolts useable
	lxi	h,BUL1+(2*Blength)	;check 3rd bolt on
	push	d
	lxi	d,Blength	;delta to next bolt
..lp:	mov	a,m		;check vx.vy=0
	ora	a
	jrz	..OK		;have a bolt
	dad	d
	djnz	..lp
	pop	d
..exit: pop	psw
	pop	b
	pop	h		;timer
	ret			;no bolt
; Have Bolt Will Shoot
..OK:	pop	d
;HL now points at bullet to use
;now check if man is up or down from you
	mov	a,d		;d=delta x
	cpi	-2
	jnc	FIREY		;out of range
	cpi	6
	jrc	FIREY
;check for a left or right shot
	mov	a,e		;e=delta y
	cpi	-10
	jrnc	FIREX
	cpi	2
	jrc	FIREX
;check for a diagonal shot
	mov	a,d		;abs[delta x]
	bit	0,C		;bit left
	jrz	..dox
	neg
	mov	d,a
..dox:	mov	a,e		;abs[delta y]
	bit	2,C		;bit up
	jrz	..doy
	neg
	mov	e,a
..doy:	sub	d		;if (|dX|-|dY|)
	cpi	-10		;is in range then shoot
	jrnc	FIRE
	cpi	6
	jrnc	..exit
	jmpr	FIRE
;make shot go horizontal
FIREX:	mov	a,c
	ani	3
	mov	c,a
	jmpr	FIRE
;make vertical shot
FIREY:	mov	a,c
	ani	0CH
	mov	c,a
	jmpr	FIRE
;---------------------------------------
; set up robot and bolt
;---------------------------------------
;hl->bolt,c=direction(DURL)
FIRE:
	push	h		;save bolt pointer
; zero the whole bolt
	mvi	b,Blength
	xra	a
..zap:	mov	m,a
	inx	h
	djnz	..zap		;b=0
	call	SRFIRE#		;make noise
	lxi	h,D.TAB		;translate DURL to clock
	dad	b		;b=0,c=durl
	mov	c,m		;direction offset
	lxi	h,S.TAB
	dad	b		;entry 2
	dad	b		;4
	dad	b		;6
	mov	V.X(x),B	;b=0
	mov	V.Y(x),B	;robot stops moving
	mov	a,m		;get pattern address
	inx	h
	di
	mov	D.P.L(x),A
	mov	a,m
	mov	D.P.H(x),A
	ei
	inx	h
	mvi	TIME(x),1	;make it write
	mov	b,m		;xoffset
	inx	h
	mov	c,m		;yoffset
	inx	h
	mov	d,m		;vx.vy
	mov	a,P.X(x)	;calc offset from robot
	add	B
	mov	b,a
	mov	a,P.Y(x)	;same for y
	add	C
	mov	c,a
	pop	h		;-> bolt
	mov	a,d
	ori	3		;length of bolt
	di
	mov	m,a		;vx.vy
	inx	h
	mov	m,b		;xposition
	inx	h
	mov	m,c		;yposition
	inx	h		;repeat for tail
	mov	m,b		;xposition
	inx	h
	mov	m,c		;yposition
	ei
	pop	psw		;durl
	pop	b		;tracker
	pop	h		;timer
	mvi	m,10
..wlp:	call	NEXT.J
	bit	INEPT,V.STAT(x)
	jrnz	..sk
	mov	a,m
	ora	a
	jrnz	..wlp
..sk:
; wait is lesser of (Robots*4)+5 or (Rwait/2)
; RWait comes into play later in the game
	lda	Robots		;bolt hold off
	add	a
	add	a
	adi	5		;was 10
	mov	c,a		;save this delay
	lda	Rwait
	srlr	a
	cmp	c		;compare and use
	jrc	..t		;lesser delay
	mov	a,c
..t:	mov	m,a
	mvi	C,10H		;force new setpat
	jmp	R.ret
;
.define SS[Xoffset,Yoffset,Pat,Dir]=[
	.word	Pat
	.byte	Xoffset
	.byte	Yoffset
	.byte	Dir<4
	.byte	0
]
; shoot table
;
S.TAB:	SS	0,0,S.0,0	;0
	SS	5,0,S.0,6	;1ur
	SS	6,1,S.0,2	;2r
	SS	6,2,S.0,10	;3dr
	SS	6,10,S.0,8	;4d
	SS	0,2,S.0,9	;5dl
	SS	0,1,S.0,1	;6l
	SS	0,0,S.0,5	;7ul
	SS	5,0,S.0,4	;8u

	.end

