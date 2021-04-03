B>type gameover.asm

.title	"Game Over Show"
.sbttl	"FRENZY"
.ident	GOVER
;~~~~~~~~~~~~~~~~~~~~~~~
;	game over
;_______________________
.insert equs
.intern GOVER,CLEAR,INSERT
.intern LINE,LTABLE
.extern SHOWN,SHOWO,SHOWA,SHOWC,GETC,CREDS,SHOWS
.extern C.GO,C.L1,C.L2,C.LI,PH1,NoVoice,Zap

; macros
.define WROTE[Magic,X,Y,String]=[
	call	SHOWA
	.byte	Magic,X,Y
	.asciz	String
]
; language tabled subroutine call
.define LANG[Name]=[
	call	LTABLE
	.word	E.'Name		;;English
	.word	G.'Name		;;German
	.word	F.'Name		;;French
	.word	S.'Name		;;Spanish
]
; equates
S.END	==	EndScreen
LINE1	==	190
;---------------------------------+
; clear screen and show copyright |
;---------------------------------+
GOVER:	call	CLEAR		; erase.screen
	call	C.GO		; setup color gameover
	call	CREDS		;show credits
	call	SHOWS		;show scores
;----------------------------+
; show high scores and names |
;----------------------------+
	call	SmallTitle#	;FRENZY
	LANG	High
	lxi	h,56*Hsize+Screen	; start position
	call	LINE
	lxi	h,HIGH1		; first high score
	mvi	A,1
	sta	TEMP		; number 1 line
	lxi	d,63<8!64	; YX position
..loop: push	d
	push	h
	mov	a,m		;if score is zero dont show it
	inx	h
	ora	m
	inx	h
	ora	m
	pop	h
	push	h
	jrnz	..skip
	pop	h
	pop	d
	jmpr	DRAW
..skip: lxi	h,TEMP		; shown line number
	mvi	B,2		; 2 digits long
	call	SHOWN
	inx	d		; spc over one byte
	pop	h
	mvi	B,6		; shown high score,6digits
	call	SHOWO
	inx	d		;space over
	xra	a		;plop write
	mov	c,m
	call	SHOWC
	inx	d
	inx	h
	mov	c,m
	call	SHOWC
	inx	d
	inx	h
	mov	c,m
	call	SHOWC
	inx	h		; -> next high score
	pop	d
	mov	a,d
	ADI	12
	mov	d,a
	lda	TEMP
	ADI	1
	daa
	sta	TEMP
	cpi	11H
	jnz	..loop
;------------+
; draw lines
;------------+
DRAW:	lxi	h,184*Hsize+Screen
	call	LINE
	lxi	h,204*Hsize+Screen
;	call	line
;	2
;------------------+
; draw line across |
;------------------+
LINE:	mvi	A,0FFH
	mvi	B,64
L.LOP:	mov	m,a
	inx	h
	djnz	L.LOP
	ret
;--------------+
; erase screen |
;--------------+
CLEAR:	lxi	h,ColorScreen
	lxi	b,700H
	call	Zap
	di
	sspd	Temp
	lxi	sp,S.END+1
	mvi	B,Vsize
	lxi	d,0
E.L:	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	push	d
	djnz	E.L
	lspd	Temp
	ei
; set flip state by player number
SFLIP:	in	I.O3		;is it a cocktail
	bit	7,A
	jrnz	Normal		;if not cocktail
	lda	PLAYER		;is cocktail version
	cpi	2		;flip screen? for player2
	jrnz	Normal
	mvi	A,8		;the flip bit
	sta	FLIP
	ret
Normal: xra	a
	sta	FLIP
	ret
; Copyright
CopyR:: call	SHOWA			; @ 1980 stern electronics
	.byte	90H
	.byte	12,LINE1,1FH
	.asciz	"1982 STERN Electronics, Inc."
	ret
;---------------------------+
; insert coin / press start |
;---------------------------+
INSERT: CALL	LERASE		;erase line for text
	call	GETC		;get credits
	jrz	INSSS
	dcr	a
	jrz	PRESS1
	call	C.L2
	LANG	Pus2
	ret
;
PRESS1: CALL	C.L1
	LANG	Push1
	ret
;
INSSS:	call	C.LI
	LANG	In
; coins detected in pocket
	lxi	h,PH1		;phrase
	shld	V.PC		;into voice pc
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~
; xtra man level 
;__________________________
XMLEV:: call	LERASE
	in	Dip2
	ani	15		;# of k for extra man
	jrz	..cheap
	mov	b,a
	ani	8
	mov	c,a
	mov	a,b
	ani	7
	add	c
	daa			;now its in BCD
	sta	TEMP
	lxi	d,LINE1<8!88	; y:x position
	lxi	h,TEMP		; number
	mvi	B,2		; 2 digits long
	call	SHOWN		; show it
	WROTE	90h,104,LINE1,"000 = ~"
	ret
..cheap:
	WROTE	90H,72,LINE1,"No Extra Lives"
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~
; erase line for messages
;__________________________
LERASE: lxi	h,LINE1*Hsize+Screen
	lxi	b,2C0H		;2 lines less than 16
	xra	a
LELE:	mov	m,a
	inx	h
	dcr	c
	jnz	LELE
	djnz	LELE
	ret
;---------------------------------+
; Language tabled subroutine call |
;---------------------------------+
LTABLE: pop	h		;get table address
	mov	d,h
	mov	e,l		;save table address
	lxi	b,8		;offset to end of table
	dad	b		;calc return address
	push	h		;put return address on stack
	xchg			;get table address
	in	diP2		;get language bits
	ani	0C0H
	rlc			;rotate bits into low bits
	rlc
	rlc			;A=language#*2
	mov	c,a		;BC=language#*2
	dad	b		;address into table
	mov	a,m		;get low address
	inx	h
	mov	h,m		;get high address
	mov	l,a		;HL=subroutine address
	pchl
;------+
; Text |
;------+
E.High: WROTE	90H,80,42,"High Scores"
	ret
F.High: WROTE	90H,68,42,"Meilleur Score"
	ret
G.High: WROTE	90H,60,42,"Hoechster Gebnis"
	ret
S.High: WROTE	90H,96,42,"Records"
	ret
;-------------------------
E.Push1: WROTE	90H,20,LINE1,"Push 1 Player Start Button"
	ret
F.Push1: WROTE	90H,36,LINE1,"Pousser bouton start 1"
	ret
;-------------------------
E.Pus2: WROTE	90H,4,LINE1,"Push 1 or 2 Player Start Button"
	ret
F.Pus2: WROTE	90H,16,LINE1,"Pousser bouton start 1 ou 2"
	ret
G.Push1:
G.Pus2: WROTE	90H,32,LINE1,"Startknoepfe druecken"
	ret
S.Push1:
S.Pus2: WROTE	90H,68,LINE1,"Pulsar Start"
	ret
;-----------------
E.In:	WROTE	90H,88,LINE1,"Insert Coin"
	ret
F.In:	WROTE	90H,48,LINE1,"Introduire la monnaie"
	ret
G.In:	WROTE	90H,72,LINE1,"Munze einwerfen"
	ret
S.In:	WROTE	90H,72,LINE1,"Ponga la moneda"
	ret

	.end

