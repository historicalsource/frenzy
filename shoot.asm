B>type shoot.asm

.title	"SHOOT AT MAN"
.sbttl	"FRENZY"
.ident SHOOT
;---------------------------------------
; if (a bolt is available) then
; if (it is possible to shoot at the man)
;	Shoot;
;---------------------------------------
.insert equs
.extern D.TAB,SETPAT,NEXT.J
; a=DURL to man
; hl->timer
SHOOT::
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
	cpi	8
	jrc	FIREY
;check for a left or right shot
	mov	a,e		;e=delta y
	cpi	-10
	jrnc	FIREX
	cpi	5
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
	jmp	R.ret#
;
.define SS[Xoffset,Yoffset,Pat,Dir]=[
	.word	Pat
	.byte	Xoffset
	.byte	Yoffset
	.byte	Dir<4
	.byte	0
]
;
; shoot table
;
.extern R.0
S.TAB:	SS	0,0,R.0,0	;0
	SS	7,1,R.0,6	;1ur
	SS	8,2,R.0,2	;2r
	SS	8,4,R.0,10	;3dr
	SS	6,11,R.0,8	;4d
	SS	-1,4,R.0,9	;5dl
	SS	-1,2,R.0,1	;6l
	SS	0,1,R.0,5	;7ul
	SS	6,0,R.0,4	;8u
	.end
