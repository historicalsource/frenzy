B>type demo.asm

.title	"Demo Game"
.sbttl	"FRENZY"
.ident DEMO
;~~~~~~~~~~~~~~~~~~
;    Demo Mode
;------------------
.insert equs
.extern PLAY,ScorePtr
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Play Demo Game
;-----------------------------
PLAYDEMO::
	call	ScorePtr	;point at players score
	lxi	d,SavedScore
	call	ScoreMove

	lhld	Seed
	push	h

	lxi	h,DemoData	;fake the control
	shld	DemoPtr		; inputs data

	mvi	A,-1		;set to demo mode
	sta	Demo
	xra	a
	sta	WallPts

	lxi	b,Other-Player	;move demo setup data
	lxi	d,Player	; into player data
	lxi	h,D.DATA
	ldir

	call	PLAY		;play one deaths worth

	pop	h		;restore random number seed
	push	psw		;save button status
	shld	Seed
	call	RANDOM		;do another randomize

	call	ScorePtr	;restore old player score
	lxi	d,SavedScore
	xchg
	call	ScoreMove

	pop	psw		;restore button status
	jmp	DemoRet#

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Move Score and Zero Source
;--------------------------------------
ScoreMove:
	mvi	B,3		;score bytes
ZapLoop:
	mov	a,m		; get score byte
	mvi	M,0		;zero it
	inx	h
	stax	d		;store in save area
	inx	d
	djnz	ZapLoop
	ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Random Number Generator
;--------------------------------------
RANDOM::
	push	h
	lhld	Seed
	mov	d,h
	mov	e,l
	dad	h
	dad	d
	dad	h
	dad	d
	lxi	d,3153H
	dad	d
	shld	Seed
	mov	a,h
	pop	h
	ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Demo Game Initialization Data
;--------------------------------------
; Player Info Area
;Player	 Player # of this player
;RoomX	 room #
;ManX	 mans room-exit position
;MPY=	 ManX+1
;DEATHS	 # of man lives
;PERCENT %  of robots
;Rbolts	 # of robot bolts
;Rtime	 robot speed
;Rwait	 robot hold off time
;STIME	 time until otto attacks
;XtraMen=extra man flags
;--------------------------------------
D.DATA: .byte	1	;Player
	.byte	20,40	;RoomX
	.byte	30	;ManX
	.byte	116	;MPY
	.byte	1	;DEATHS
	.byte	8	;PERCENT
	.byte	1	;Rbolts
	.byte	32	;Rwait
	.byte	4	;STIME
	.byte	0	;XtraMen
	.byte	8	;RoomCnt
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Fake Control Input Data
; if bit 7=1 then it is a delay of(X  7fh) 60ths
;--------------------------------------
DemoData:
.byte	01h,8fh,18H,05H,8Fh,1Ah,14h,02h,9Fh,1Ah,02h,94h,16h,0Ah,92h,16h
.byte	02h,0BFh,14h,8Fh,09h,9Fh,1Ah,8Fh,14h,8Fh,09h,0BFh,02h,0BFh,14h,8Fh
.byte	14h,8Fh,0Ah,94h,0Ah,9Fh,02h,0CFh,14H,-1,11h,11h,11h,11h,11h,11h
.byte	11h,11h,11h,11h,11h,9Fh,12h,04h,9fh,16h,9fh,14h,0,-1,-1,-1

	.end
