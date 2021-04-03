B>type play.asm

.title	"PLAY A ROUND"
.sbttl	"FRENZY"
.ident PLAY
;--------------+
; PLAY A ROUND |
;--------------+
.insert equs
.intern PLAY,ScorePtr,REST,ADDS,SHOWS
.extern COINCK,ItemInc,RANDOM,C.MOVE,SHOWN
;-----------------------
; PLAY 1 ROUND OF ROBO
;-----------------------
PLAY:	pop	h
	shld	PlayRet
	call	CLEAR#		;ERASE Screen
	call	ROOM#		;DRAW ROOM
	lda	Demo		;IF DEMO DONT FLASH MAN
	ora	a
	jrnz	AGAIN
; FLASH MAN
	call	M.INIT#
	lxi	b,(16<8)!(1<COLOR)!(1<WRITE)
	lda	N.PLRS
	cpi	2
	jrz	..lp
	mvi	B,6		;short flashing
..lp:	mov	V.STAT(x),c	
	WAIT	10
	mvi	A,(1<COLOR)!(1<BLANK)!(1<WRITE)!(1<ERASE)
	xra	c
	mov	c,a
	djnz	..lp
	call	REST		;vector initialize
;PLAY AGAIN LOOP
AGAIN:	ei
	xra	a
	sta	IqFlg
	sta	WallPts
	mvi	a,90		;(otto resets it)
	sta	KWait		;killoff wait
	lda	PERCENT		;figure new percent
..ad:	adi	6
..lp:	cpi	22+1
	jrc	..ok
	sui	22
	cpi	7
	jrc	..ad
	jmpr	..lp
..ok:	sta	PERCENT
	sta	MEMPHS
	FORK	MAN#
	FORK	SUPER#
	lda	RoomCnt
	ORA	A
	JRZ	..NSP
	ani	3		;test for special room
	jrnz	..nsp
	FORK	FACTORY#
..nsp:	xra	a
	sta	Robots
; start up man,robots,otto
..rlp:	FORK	ROBOT#
	lxi	h,PERCENT
	dcr	m
	jrnz	..rlp
	lda	MEMPHS
	sta	PERCENT
;--------------------------------
; TEST FOR MAN DEAD [GAME OVER]
;--------------------------------
TLOP:	call	NEXT.J#
	lxi	x,Vectors	;man vector
	bit	MOVE,0(x)	;if no moving he's dead
	jz	DEAD
	mov	a,P.Y(x)	;STORE LATEST X AND Y
	sta	ManY		;INTO INITIAL X,Y
	mov	b,a
	mov	a,P.X(x)
	sta	ManX
	bit	INEPT,0(x)
	jnz	NoWAY		;skip tests if man is hit
	lxi	D,AGAIN		;common return address after
	push	D		;scrolling
	cpi	5
	jc	OLEFT
	cpi	246
	jnc	ORIGHT
	mov	a,b
	cpi	5
	jc	OUP
	cpi	190
	jnc	ODOWN
	pop	D
;not off edges
NoWAY:	call	Awpts		;award wall pts
	lda	UPDATE		;if score hasn't changed
	ora	a		;then skip
	cnz	SHOWS		;show score
	lda	Kwait		;killoff?
	ora	a
	jrnz	..nk
	dcr	a
	sta	KWait
	FORK	KLUTZ#
..nk:	lda	Demo		;TEST FOR Demo GAME
	ora	a
	jrz	..sk
; if in a demo game
	call	COINCK		;show new coins
..sk:
	jmp	TLOP
;return to go or main
DEAD:	call	NoSnd#
	lhld	PlayRet		;return to caller
	pchl
;-------------------------
; MOVED OFF EDGE ROUTINES
;-------------------------
ODOWN:	mvi	A,10
	sta	ManY
	lxi	h,RoomX+1
	inr	m
	lxi	h,RoomUp#		;type of room routine
	push	h			;to execute after scroll
	call	TREST
	jrz	NorD
	lxi	d,Screen+223*Hsize-1
	jmp	S.D
NorD:	lxi	d,Screen
;--------------------
;	SCROLL UP
;--------------------
S.U:	mvi	A,27
..lp:	lxi	h,8*Hsize
	dad	d
	lxi	b,200*Hsize
	push	d
	ldir			;scroll up 8 lines
	pop	d
	lxi	b,8*Hsize
..lp2:	dcx	h		;clear junk under room edge
	mvi	M,0
	dcr	c
	jnz	..lp2
	djnz	..lp2
	dcr	a
	jrnz	..lp
	ret			;will goto RoomXX then AGAIN
;---------------------
;	OFF TOP
;---------------------
OUP:	mvi	A,178
	sta	ManY
	lxi	h,RoomX+1
	dcr	m
	lxi	h,RoomDown#		;type of room routine
	push	h			;to execute after scroll
	call	TREST
	jrz	NorU
	lxi	d,Screen+16*Hsize
	jmp	S.U
NorU:	lxi	d,208*Hsize+Screen-1
;---------------------
;	SCROLL DOWN
;---------------------
S.D:	mvi	A,26
DL:	lxi	b,200*Hsize
	lxi	h,-8*Hsize
	dad	d
	push	d
	lddr
	pop	d
	lxi	b,8*Hsize
DL2:	inx	h
	mvi	M,0
	dcr	c
	jnz	DL2
	djnz	DL2
	dcr	a
	jrnz	DL
	ret			;goes to room,again
;---------------------
; OFF RIGHT EDGE
;---------------------
ORIGHT: mvi	A,19
	sta	ManX
	lxi	h,RoomX+0
	inr	m
	lxi	h,RoomLeft#		;type of room routine
	push	h			;to execute after scroll
	call	TREST
	jrz	NorR
	lxi	d,Screen+223*Hsize
	jmp	S.R
NorR:	lxi	d,Screen
;---------------------
;	SCROLL LEFT
;---------------------
S.L:	mvi	a,Hsize
LL:	lxi	b,Hsize*208-1
	lxi	h,1
	dad	d
	push	d
	ldir
	mvi	B,208
	lxi	d,-Hsize+1
LL2:	mvi	M,0
	dcx	h
	mvi	M,0
	dad	d
	djnz	LL2
	pop	d
	dcr	a
	jrnz	LL
	ret			;goes to room,again
;---------------------
;	OFF LEFT EDGE
;---------------------
OLEFT:	mvi	A,228
	sta	ManX
	lxi	h,RoomX+0
	dcr	m
	lxi	h,RoomRight#		;type of room routine
	push	h			;to execute after scroll
	call	TREST
	jrz	NorL
	lxi	d,Screen+16*Hsize
	jmp	S.L
NorL:	lxi	d,Screen+208*Hsize
;---------------------
;	SCROLL RIGHT
;---------------------
S.R:	mvi	a,Hsize
XRL:	lxi	b,Hsize*208
	lxi	h,-1
	dad	d
	push	d
	lddr
	lxi	d,Hsize-1
XRL2:	mvi	M,0
	inx	h
	mvi	M,0
	dad	d
	djnz	XRL2
	pop	d
	dcr	a
	jrnz	XRL
	ret			;goes to room,again
;----------------------------
; STOP TALKING,MOVES & COLOR
;----------------------------
TREST:	call	C.MOVE
REST:	di
	call	STOP.B
	lxi	h,Vectors+VLEN
	shld	L.PTR
	lxi	h,Vectors
	shld	V.PTR
	lxi	b,VLEN*MaxVec
	call	Zap#
	call	JobInit#
	call	TimerInit#
	lda	FLIP
	ora	a
	ret
;---------------------
; STOP BULLET VECTORS
;---------------------
STOP.B: lxi	h,BUL1
	lxi	b,Blength*Bolts
	call	Zap
	ret
;-------------
; SHOW	SCORE
;-------------
SHOWS:	xra	a
	sta	UPDATE
	lxi	d,213*256+0
	lxi	h,SCORE1
	mvi	B,6
	call	SHOWN
	lda	N.PLRS
	cpi	2
	rnz	
	lxi	d,213*256+176
	lxi	h,SCORE2
	mvi	B,6
	jmp	SHOWN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  ->HL AT PLAYERS SCORE
;_______________________________
ScorePtr:
	lda	PLAYER
	cpi	2
	lxi	h,SCORE2
	rz	
	lxi	h,SCORE1
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Award wall points
;_______________________________
Awpts:	lxi	h,WallPts
	mov	a,m		;check wall points
	ora	a
	rz
	mov	c,a		;save score
	NEG
	di			;points maybe awarded in int by now
	add	m		;sub the point awarded
	mov	m,a		;update it
	ei
	mov	a,c
	push	psw
	rrc			;get 10's
	rrc
	rrc
	rrc
	mvi	b,1		;10's
	call	..awd
	pop	psw
	mvi	b,0		;1's
..awd:	ani	0fh		;isolate score
	mov	c,a		;save in c for adds
	lda	Wpoint		;multiplier
..1:	push	psw
	push	b
	call	ADDS		;score 1's
	pop	b
	pop	psw
	dcr	a		;dec multiplier
	jrnz	..1
	ret
;------------------------+
; ADD C X 10**B TO SCORE |
;------------------------+
ADDS:	mvi	A,0FFH
	sta	UPDATE
	mvi	E,3+1		;NUMBER OF BYTES
	call	ScorePtr
	inx	h
	inx	h
	inx	h
	srlr	B		;DIVIDE BY 2, REMAINDER TO CARRY
	exaf			;SAVE CARRY
	inr	b
..lp:	dcx	h
	dcr	e		;ONE LESS BYTE
	djnz	..lp
; HL->SCORE BYTE CARRY FLAG = ODD/EVEN, C=VALUE
	exaf			;RESTORE CARRY
	jrnc	..skp
	slar	C		;SHIFT SCORE
	slar	C
	slar	C
	slar	C
..skp:	mov	a,e		;byte number
	cpi	2		;checking for thousands
	jrz	..td
	mov	a,c		;add score
	add	M
	daa
	mov	m,a
	jrnc	..done
..entr: dcx	h
	mvi	C,1
	dcr	e		;ONE LESS BYTE
	jrnz	..skp
..done: ret

; test thousands for extra man award
..td:	mov	a,m
	mov	b,a		;save it
	add	c		;add score
	daa
	mov	m,a
	mvi	c,2		;flag for add 1 to next
	jrc	..noc		;if carry then 2 else 1
	dcr	c		;c=1
..noc:	ani	0F0h		;isolate top nibble
	exaf
	mov	a,b		;do same to b
	ani	0F0h
	mov	b,a
	exaf
	sub	b		;check for change
	daa
	jrz	..ext
	rrc
	rrc
	rrc
	rrc			;1-10 bcd
;now see if time for extra life
	mov	b,a		;save change
	lda	XtraMen
	ora	a
	jrz	..ext
	sub	b		;b=#of 1k's
	jrc	..give		;should be Minus?
	jrz	..give
	sta	XtraMen		;put away extra life accum
..ext:	dcr	c
	jz	..done
	jmp	..entr
;award extra life
..give: mov	b,a		;save negative or zero remainder
	in	DIP2		;get extra life dip
	ani	15		;0-15
	sub	b		;sub remainder
	sta	XtraMen
	push	b
	push	d
	push	h
	lxi	h,DEATHS
	inr	m		;inc [deaths]
	call	SXLIFE#
	call	SHOWD#
	pop	h
	pop	d
	pop	b
	jmp	..ext

	.end
