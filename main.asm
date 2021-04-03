B>type main.asm

.title	"MAIN LOOP"
.sbttl	"FRENZY"
.ident MAIN
;----------------------
;	main loop
;----------------------
.insert equs
.extern GOVER,INSERT,PLAYDEMO,NMI,JobInit
.extern REST,INT,MOVEN
.extern UPHIGH,PLAY,SHOWN,RANDOM
.extern DECCRD,NoVoice,NoSnd,ItemInc
DEATH2	==	DEATHS+(OTHER-PLAYER)
;----------------------
; start of main module
;----------------------
MAIN::	di			;initial
	lxi	sp,SPos		;set stack
;zero locations for sounds and battery ram scratch
	lxi	h,SPos
	lxi	b,T60cnt-SPos	;# of bytes
	call	Zap
; zero above screen ram
	lxi	h,VideoRAM
	lxi	b,ScreenRAM-VideoRam
	call	Zap
;start sounds
	call	66h		;nmi routine
;move high scores from backup
	call	CheckBooks#
	lxi	h,HIGH1		;shown
	lxi	d,HIGH2		;backed up
	mvi	B,5*12		;# of nibbles
	call	MOVEN
;setup debouncer coin switches
	in	I.O2
	cma
	lxi	h,SWD		;switch debouncer
	mov	m,a
	inx	h
	mov	m,a
; main attract loop
MLOOP::
	lxi	sp,SPos		;reset stack
	xra	a
	sta	StartB		;no start yet
	call	SET1		;reset everything
	call	TITLE#
	call	CheckBooks
	mvi	b,8
	call	COIN1#
MENTR:	xra	a
	sta	StartB		;no start yet
	call	GOVER		;high score display
	call	INSERT		;insert coin/press start
	mvi	b,3
	call	COIN1#		;check coins and wait
	call	XMLEV#		;insert coin/press start
	call	COIN0#		;check coins and wait
	jmp	PLAYDEMO	;play a demo game
DemoRet::
	jz	MLOOP
	jmp	GO		;play a complete game
;---------------
SET1:	di
	xra	a
	sta	player		;forces upside up mode
	dcr	a		;-1
	sta	DEMO		;is demo mode
	call	JobInit
	call	REST		;stop bolt and vectors
	mvi	a,55h		;alternater
	sta	IntTyp
	call	INT		;start interrupts
	ret
;-----------------------
; Play 1 complete game
;-----------------------
; take away credits and go play a game
GO::
	lxi	sp,SPos		;reset stack
	lxi	h,StartB
	set	7,m		;no jump while playing
	call	SET1		;reset everything
	lda	StartB
	mov	l,a
	call	DECCRD		;take away 1st player credit
	bit	1,L		;test for 2 player button
	mvi	A,1		;# of players:=1
	jrz	..st		;0=one player game
	call	DECCRD		;take away 2nd player credit
	mvi	A,2		;# of players:=2
..st:	sta	N.PLRS		;store # of players
	cpi	2
	jrz	..two
	mvi	c,3		;1 player plays
	call	ItemInc
	jmpr	..tp
..two:	mvi	c,4		;2 player games
	call	ItemInc
	mvi	c,5		;total plays
	call	ItemInc
..tp:	mvi	c,5		;total plays
	call	ItemInc
	call	ZSCORE		;zero the score
	lxi	b,OTHER-PLAYER
	lxi	d,PLAYER
	lxi	h,Idata
	ldir			;initial the player
	lhld	SEED
	xchg
	lhld	OnTime+10	;part of second count
	dad	d
	shld	SEED		;new random room
	shld	RoomX
	in	Dip2		;extra lives
	ani	15
	sta	XtraMen
	xra	a
	sta	DEMO		;not a demo
	sta	CHIKEN		;not a chicken yet
	sta	RoomCnt		;hasn't seen any rooms yet
	inr	a
	sta	T.TMR		;set talk timer for 1 second
	lxi	h,PLAYER	; Set 2nd players bank
	lxi	d,OTHER
	lxi	b,OTHER-PLAYER
	ldir
	mvi	A,2		;SET AS PLAYER NUMBER 2
	mov	m,a
; Turn second player off if 1 player game
	lda	N.PLRS
	cpi	2
	jrz	SLOP
	xra	a		;if no deaths
	sta	DEATH2		; then no playing either
SLOP:	ei
	lhld	Manxi
	shld	ManX
	lda	PLAYER
; Play out one life
	call	PLAY
	call	RANDOM
	WAIT	90		;pause to show trouble
	call	REST		;stop moving stuff on screen
	lhld	SEED		;goto a new random room
	shld	RoomX
	lxi	h,DEATHS	;take away a life
	dcr	m
	call	SWAP		;swap to other player
	jrnz	SLOP		;if so go play his round
	call	SWAP		;do you have any lives left?
	jrnz	SLOP
; Update High Scores
	mvi	a,-1
	sta	DEMO		;not playing anymore
	call	NoSnd
UPITY:	call	UPHIGH		;Check for high score
;get other player
	call	SWAP		;(in 1 player its score is 0)
	call	UPHIGH		;Check for high score
	lxi	sp,SPos		;reset stack
	call	SET1		;reset everything
	jmp	MENTR		;right to high scores
;---------------------------
; ZERO both players scores
; and can the 1/2 credits
;---------------------------
ZSCORE: lxi	h,0
	shld	SCORE1
	shld	SCORE1+2
	shld	SCORE2+1
	shld	CACKLE		;zero fractional coin
	lxi	h,NoVoice
	shld	V.PC
	jmp	NoSnd
;----------------------------
; Swap players banks of ram
;----------------------------
SWAP:	push	h
	lxi	h,PLAYER
	lxi	d,OTHER
	mvi	B,OTHER-PLAYER
..LP:	ldax	d
	mov	c,m
	xchg
	stax	d
	mov	m,c
	xchg
	inx	h
	inx	d
	djnz	..LP
	pop	h
	mov	a,m
	ora	a
	ret
;---------------------------
; zero ram loop
; hl->start, bc=# of bytes
;---------------------------
Zap::	mov	a,c
	ora	a
	mov	c,b
	mov	b,a
	jrz	..sk
	inr	c
..sk:	xra	a
..zl:	mov	m,a
	inx	h
	djnz	..zl
	dcr	c
	jrnz	..zl
	ret
;---------------------------------------------+
; Initialization data for players first round |
;---------------------------------------------+
Idata:	.byte	1	;PLAYER
	.byte	0,0	;RoomX
Manxi:	.byte	30	;ManX
	.byte	116	;MPY
	.byte	3	;DEATHS
	.byte	6	;PERCENT
	.byte	0	;Rbolts
	.byte	90	;Rwait
	.byte	0	;STIME
	.byte	0	;XtraMen

	.end

