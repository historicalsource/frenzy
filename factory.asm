B>type factory.asm

.title	"Robot Factory & MaMa Otto"
.sbttl	"FRENZY"
.ident	FACTORY
.insert equs
.extern RtoAx,PLOT,V.ZERO
; MACROS
RD=8	;room drop
XX=120+RD	;x of left edge
YY=48+RD	;y of top corner
.define START[Pat,Xoff,Yoff]=[
	lxi	h,Pat#
	lxi	d,((Yoff+YY)<8)!(Xoff+XX)
	call	%START
]
.define DRAW[Pat,Xoff,Yoff]=[
	lxi	d,Pat#
	lxi	h,((Yoff+YY)<8)!(Xoff+XX)
	call	%DRAW
]
.define COLOR[Ctable]=[
	lxi	h,Ctable
	call	%Color
]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	ROBOT FACTORY
;_______________________________
FACTORY::
	lda	RoomCnt
	bit	3,a
	jz	..8
	bit	2,a
	jz	Plant		;do mama otto 1
	jmp	Compu		;2
..8:	bit	2,a
	jnz	MaMa		;2
; 4-factory is farthest
	COLOR	FCOLS
	DRAW	PTA,3,3
	DRAW	PTB,4,18
	DRAW	PTC,12,16
; 4 vectored parts (Conveyor,Handle,WhirlCCW,WhirlCW)
	START	C.IDLE,8,8
	START	H.IDLE,28,32
	START	W.CCW,14,29
	mvi	TPRIME(x),1
	START	W.CW,19,36
	mvi	TPRIME(x),1
	pop	B		;wcw save vector pointers
	pop	B		;wccw
	pop	D		;handle
	pop	X		;conveyor
..n:	call	NEXT.J#
	lda	Robots
	ora	a
	jm	..go
	cpi	13
	jrnc	..n
; start one up
..go:	lxi	h,C.PART#	;go conveyor
	call	ChangePat		
	WAIT	50
	push	d		;ex ix,iy
	xtix
	pop	d
	lxi	h,H.GO#
	call	ChangePat
	WAIT	60
	FORK	FROBOT#
	WAIT	90
	lxi	h,H.IDLE#
	Call	ChangePat
	push	d		;ex ix,iy
	xtix
	pop	d
	WAIT	30		;idle
	jmpr	..n
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Mother Otto
;_______________________________
MaMa:	call	M.TALK#
	COLOR	MCOLS
	DRAW	MAL,4,4
	DRAW	MAR,20,4
	call	Sleep
..sl:	call	NEXT.J
	lda	CACKLE+1	;ottos hit
	ora	a
	jrnz	..xsl		;stay asleep
	lda	Vectors		;check on man
	bit	INEPT,a
	jrz	..sl
	call	UnM
	jmpr	..xdl
..xsl:	call	Sleep		;erase old
	call	Angry
	lxi	d,(82<8)!110
	FORK	MSUPER#
	lxi	d,(82<8)!170
	FORK	MSUPER
	lxi	d,(40<8)!148
	FORK	MSUPER
	lxi	d,(90<8)!148
	FORK	MSUPER
..dl:	call	NEXT.J
	lda	Vectors		;check on man
	bit	INEPT,a
	jrz	..dl
	call	AngryM		;erase old mouth
..xdl:	call	Smile	
	jmp	JobDEL#		;no need for me any more
;draw smile
Smile:	DRAW	MASML,4,30
	DRAW	MASMR,20,30
	RET
;draw eyes and mouth angry
Angry:	DRAW	MAEL,11,9
	DRAW	MAER,21,9
	COLOR	ECOLS
AngryM: DRAW	MAFL,4,30
	DRAW	MAFR,20,30
	ret
;draw eyes and mouth sleep
Sleep:	DRAW	MASL,4,13
	DRAW	MASR,20,13
UnM:	DRAW	MAM,12,30
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Electric Plant
;_______________________________
Plant:
	COLOR	PLCOLS
	call	UnReflect
	DRAW	BULB,8,4
	DRAW	BULB,8,20
	DRAW	BULB,28,12
	DRAW	STALK,28,28
	DRAW	RFILL,3,36
	DRAW	FILL,16,36
	DRAW	RFILL,28,36
; 4 vectored parts (W.CW,W.CCW,TL,BL)
	START	TL,12,7
	mvi	TPRIME(x),1
	START	BL,12,16
	mvi	TPRIME(x),1
	START	W.CCW,8,38
	mvi	TPRIME(x),1
	START	W.CW,28,38
	mvi	TPRIME(x),1
; save vector pointers
	pop	b
	pop	d
	pop	h
	pop	x
..loop: call	NEXT.J
	call	HitChk
	jrz	..loop
..Hit:	di
	ldax	b		;stop the whirlies
	res	MOVE,a
	stax	b
	ldax	d
	res	MOVE,a
	stax	d
	mov	a,m
	ani	#((1<MOVE)!(1<WRITE))
	mov	m,a
	mov	a,V.STAT(x)
	ani	#((1<MOVE)!(1<WRITE))
	mov	V.STAT(x),a
	ei
	mvi	a,2
	sta	IqFlg		;go for slow moving
	lxi	b,201h		;100
	call	ADDS#
	jmp	JobDel#
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Computer Control
;_______________________________
Compu:
	COLOR	CPCOLS
	call	UnReflect
	DRAW	RTL,4,12
	DRAW	LTL,24,12
	DRAW	Nose,18,15
; 3 vectored parts (CMS,TRCCW,TRCCW)
	START	CMS,16,2
	mvi	TPRIME(x),1
	START	CMouth,12,28
	START	TRCCW,4,4
	mvi	TPRIME(x),1
	START	TRCCW,30,4
	mvi	TPRIME(x),1
; save vector pointers
	pop	x
	pop	h
	pop	d		;mouth
	pop	b		;message
..loop: call	NEXT.J
	call	HitChk
	jrz	..loop
..Hit:	di			;stop tape reels
	ldax	b		;stop message
	ani	#(1<MOVE)
	stax	b
	mov	a,m
	ani	#(1<MOVE)
	mov	m,a
	mov	a,V.STAT(x)
	ani	#(1<MOVE)
	mov	V.STAT(x),a
;do mouth
	push	d
	pop	x
	lxi	h,CMDIE#
	mov	D.P.H(x),h
	mov	D.P.L(x),l
	ei
	mvi	a,5		;no shoot/iq
	sta	IqFlg		;go for Crasho
	lxi	b,201h		;100
	call	ADDS#
	call	C.TALK#
	jmp	JobDel#
;~~~~~~~~~~~~~~~~~~~~
; Check for man bolts
;____________________
PX=1
PY=2
HitChk: lxi	y,BUL1
	call	HC
	lxi	y,BUL1+BLength
	call	HC
	xra	a
	ret
;
HC:	mov	a,PX(y)
	cpi	XX
	rc
	cpi	XX+40
	rnc
	mov	a,PY(y)
	cpi	YY
	rc
	cpi	YY+46
	rnc
	inx	sp	;drop return address
	inx	sp
	ret		;nz
;~~~~~~~~~~~~~~~~~~~~
; Unreflecto the area
;____________________
UnReflect:
	lda	Flip
	ora	a
	jrnz	%FUC

	lxi	x,82b0h
	lxi	d,Hsize
	call	lin0
	mvi	b,11
	call	sid0
	call	lin0
; write grapes on wall
Wallo:	di
	lxi	h,3480h		;((YY-4)<8)!XX
	push	h
	call	HWB#
	pop	h
	call	VWB#
	lxi	h,34a8h		;((YY-4)<8)!(XX+40)
	call	VWB
	lxi	h,6480h		;((YY+44)<8)!XX
	call	HWB
	ei
	ret
;flip style
%FUC:	lxi	x,864fh		;flip version
	lxi	d,-Hsize
	call	lin1
	mvi	b,11
	call	sid1
	call	lin1
	jmp	wallo
;
Lin0:	mvi	b,5
	push	x
	pop	h
	lda	Wcolor
..loop: mov	m,a
	inx	h
	djnz	..loop
	mvi	b,1
;	jmp	Sid0
;
Sid0:	lda	Wcolor
	ani	0F0h
	mov	c,a
..loop: mov	a,0(x)
	ani	0Fh
	ora	c
	mov	0(x),a
	mov	a,5(x)
	ani	0Fh
	ora	c
	mov	5(x),a
	dadx	d
	djnz	..loop
	ret
;
Lin1:	mvi	b,5
	push	x
	pop	h
	lda	Wcolor
..loop: mov	m,a
	dcx	h
	djnz	..loop
	mvi	b,1
;	jmp	sid1
;
Sid1:	lda	Wcolor
	ani	0Fh
	mov	c,a
..loop: mov	a,0(x)
	ani	0F0h
	ora	c
	mov	0(x),a
	mov	a,-5(x)
	ani	0F0h
	ora	c
	mov	-5(x),a
	dadx	d
	djnz	..loop
	ret
;~~~~~~~~~~~~~~~~~~~~
; Color the area
;____________________
%Color:			;FIX FOR COCKTAIL
	lda	Flip
	ora	a
	jrnz	%FC
	lxi	x,82B0h
	lxi	d,Hsize-5
	mvi	c,12
..y:	mvi	b,5
..x:	mov	a,m
	inx	h
	mov	0(x),a
	inx	x
	djnz	..x
	dadx	d
	dcr	c
	jrnz	..y
	ret
;
%FC:	lxi	x,864fh		;flip version
	lxi	d,-Hsize+5
	mvi	c,12
..y:	mvi	b,5
..x:	mov	a,m
	inx	h
	rlc
	rlc
	rlc
	rlc
	mov	0(x),a
	dcx	x
	djnz	..x
	dadx	d
	dcr	c
	jrnz	..y
	ret
;~~~~~~~~~~~~~~~~~~~~~
; Change (ix) pattern
;_____________________
ChangePat:
	di
	mov	D.P.L(x),l
	mov	D.P.H(x),h
	ei
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~
; Draw does the xor write
;_________________________
;de=pattern hl=yx
%DRAW:	di
	call	RtoAx
	xchg
	call	PLOT
	ei
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Start a sub part
; push ix on stack on exit
%START:
	push	d
	push	h
	call	V.ZERO#
	pop	h
	pop	d
	rc
	mov	P.X(x),e
	mov	P.Y(x),d
	mov	D.P.L(x),l
	mov	D.P.H(x),h
	mvi	TIME(x),1
	mvi	TPRIME(x),2
	mvi	V.STAT(x),(1<InUse)!(1<Move)!(1<Write)	
	pop	h		;get return address
	push	x		;save vector pointer
	pchl			;return 
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Set up a square around box 9
;_______________________________
DOWN=3
UP=2
RIGHT=1
LEFT=0
S.ROOM::
	lxi	x,Walls		;set up walls
;reflecto
	set	DOWN,24+9(x)
	set	UP,24+9(x)
	set	RIGHT,24+9(x)
	set	LEFT,24+9(x)
	set	DOWN,24+3(x)
	set	UP,24+15(x)
	set	RIGHT,24+8(x)
	set	LEFT,24+10(x)
;set walls
	set	DOWN,9(x)
	set	UP,9(x)
	set	RIGHT,9(x)
	set	LEFT,9(x)
	set	DOWN,3(x)
	set	UP,15(x)
	set	RIGHT,8(x)
	set	LEFT,10(x)
;ocupied
	set	InUse,9(x)
	res	DOWN,24+15(x)		;make sure there is
	res	UP,24+21(x)		;a shootable area under
	res	RIGHT,24+14(x)
	res	LEFT,24+15(x)
	res	RIGHT,24+15(x)
	res	LEFT,24+16(x)
	ret				;the factory
;----------------------------
FCOLS:	.byte	77h,77h,77h,77h,77h	;top
	.byte	77h,77h,77h,77h,77h	;0
	.byte	77h,55h,55h,55h,77h	;1
	.byte	77h,55h,55h,55h,77h	;2
	.byte	77h,55h,55h,55h,77h	;3
	.byte	74h,41h,11h,13h,33h	;4
	.byte	74h,46h,66h,63h,33h	;5
	.byte	74h,46h,66h,63h,33h	;6
	.byte	74h,46h,66h,63h,33h	;7
	.byte	74h,46h,66h,63h,33h	;7
	.byte	74h,46h,66h,63h,33h	;7
	.byte	74h,46h,66h,63h,33h	;7

MCOLS:	.byte	77h,77h,77h,77h,77h	;top
	.byte	73h,33h,33h,33h,33h	;0
	.byte	73h,33h,33h,33h,33h	;1
	.byte	73h,33h,33h,33h,33h	;2
	.byte	73h,33h,33h,33h,33h	;3
	.byte	73h,33h,33h,33h,33h	;4
	.byte	73h,33h,33h,33h,33h	;5
	.byte	73h,33h,33h,33h,33h	;6
	.byte	73h,33h,33h,33h,33h	;7
	.byte	73h,33h,33h,33h,33h	;8
	.byte	73h,33h,33h,33h,33h	;9
	.byte	73h,33h,33h,33h,33h	;9

ECOLS:	.byte	77h,77h,77h,77h,77h	;top
	.byte	73h,33h,33h,33h,33h	;0
	.byte	73h,33h,33h,33h,33h	;1
	.byte	73h,33h,33h,33h,33h	;2
	.byte	73h,33h,33h,33h,33h	;3
	.byte	73h,31h,33h,13h,33h	;4
	.byte	73h,33h,33h,33h,33h	;5
	.byte	73h,33h,33h,33h,33h	;6
	.byte	73h,33h,33h,33h,33h	;7
	.byte	73h,33h,33h,33h,33h	;8
	.byte	73h,33h,33h,33h,33h	;9
	.byte	73h,33h,33h,33h,33h	;9

CPCOLS: .byte	77h,77h,77h,77h,77h	;top
	.byte	76h,66h,22h,26h,66h	;0
	.byte	76h,66h,22h,26h,66h	;1
	.byte	76h,66h,22h,26h,66h	;2
	.byte	76h,66h,0cch,0c6h,66h	;3
	.byte	7ch,3ch,33h,3ch,3ch	;4
	.byte	7ch,3ch,33h,3ch,3ch	;5
	.byte	7ch,3ch,11h,1ch,3ch	;6
	.byte	7ch,3ch,11h,1ch,3ch	;7
	.byte	7ch,3ch,11h,1ch,3ch	;8
	.byte	7ch,3ch,11h,1ch,3ch	;9
	.byte	7ch,0cch,11h,1ch,0cch	;9

PLCOLS: .byte	77h,77h,77h,77h,77h	;0
	.byte	73h,33h,33h,33h,33h	;1
	.byte	73h,33h,55h,53h,33h	;2
	.byte	73h,33h,55h,53h,33h	;3
	.byte	73h,66h,55h,53h,33h	;4
	.byte	73h,66h,55h,53h,33h	;5
	.byte	73h,33h,55h,56h,63h	;6
	.byte	73h,33h,55h,56h,63h	;7
	.byte	73h,66h,55h,56h,63h	;8
	.byte	73h,66h,55h,56h,63h	;9
	.byte	77h,77h,77h,77h,77h	;10
	.byte	73h,33h,33h,33h,33h	;11

	.end
