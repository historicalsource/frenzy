B>type uphigh.asm

.title	"Update High Scores"
.sbttl	"FRENZY"
.ident	UPHIGH
;-------------------+
; High Score Update |
;-------------------+
.insert EQUS
.extern CLEAR,ScorePtr,SHOWA,RtoA,SHOWC,SHOWO
.extern C.HIGH,J.WAIT,LTABLE,S.STICK,NEXT.J
.define WROTE[Magic,X,Y,String]=[
	call	SHOWA
	.byte	Magic,X,Y
	.asciz	String
]
; language tabled subroutine call
.define LANG[Name]=[
	call	LTABLE
	.word	E'Name		;;English
	.word	G'Name		;;German
	.word	F'Name		;;French
	.word	S'Name		;;Spanish
]
UPHIGH::
	CALL	ScorePtr
B.BOP:	push	h
; hl->players score
	inx	h
	inx	h		;->last byte
; add score to total
	mvi	c,6
	xchg			;->de score
	push	d
	call	ItemPtr#	;->hl at books
	mov	e,b		;->end
	mvi	d,0		; by adding offset
	dcr	e		; -1
	dad	d
	pop	d
; b=# bytes hl->books end de->score end
	mvi	c,0		;no carry flag
	ldax	d		;get score 2 digits
	dcx	d
	call	AdBtoN
	ldax	d		;get score 2 digits
	dcx	d
	call	AdBtoN
	ldax	d		;get score 2 digits
	dcx	d
	call	AdBtoN		;done with player score
	mvi	b,3		;the rest of the score area
..loop: xra	a
	call	AdBtoN
	djnz	..loop
; now xsum it
	mvi	c,6		;scum #
	call	ItemPtr
	push	h
	mvi	c,0		;put xsum in c
..xsum: mov	a,m		;add nibble to xsum
	ani	0F0h
	add	c
	mov	c,a
	inx	h
	djnz	..xsum
	pop	h
	dcx	h		;->xsum byte
	mov	m,c
;check for high score
	mvi	C,10		;number of high scores
	lxi	d,HIGH1		;-> highest high
	pop	h
..HLP:	push	h
	push	d		;save pointer to high score
	mvi	B,3		;number of bytes in high
..test: ldax	d		;get high
	cmp	m		;compare to score
	jrc	NEW.HI		;high exceeded?
	jrnz	..SKIP		;equal maybe new high
	inx	d
	inx	h
	djnz	..test
..SKIP: pop	d		;restore high pointer
	lxi	h,6		;length of high entry
	dad	d		;point to next entry
	xchg			;put in de
	pop	h
	dcr	c		;one less entry to look at
	jrnz	..HLP		;out of entries?
	ret
;------------------------+
; new high score to date |
;------------------------+
; enter new score by pushing down old ones
NEW.HI: pop	d		;get pointer to high score beaten
	push	d
	mvi	B,0		; c=number of entries left
	dcr	c
	jrz	..SK
	lxi	h,0		;hl=bc*6
	dad	b
	dad	h
	dad	b
	dad	h
	push	h		;save for later
	dad	d		;point at end
	dcx	h
	mov	d,h
	mov	e,l
	lxi	b,+6
	dad	b
	xchg
	pop	b
	lddr
..SK:	pop	d		;new high
	pop	h		;->score
	mvi	B,3
..LP:	mov	a,m
	inx	h
	stax	d
	inx	d
	djnz	..LP
	xchg
;~~~~~~~~~~~~~~~~~~~~~
; get player initials
;_____________________
	push	h
	call	CLEAR
	call	C.HIGH
	call	SHOWS#
	LANG	Line1
	exaf
	mvi	B,1
	lxi	h,PLAYER	;show player number
	call	SHOWO
	LANG	Line2
	WROTE	90H,120,98,("___")
	LANG	Line3
	call	GetTimer#
	push	h
	pop	y		;iy->timer
;get letters
	mvi	B,0
	lxi	h,96*256+120	;start char
	call	RtoA		;a=magic
	xchg
	pop	h		;restore pointer to letters
	push	h
	mvi	B,3
..fill: mvi	M,' '
	inx	h
	djnz	..fill
	pop	h
	mvi	A,30		;# of seconds to wait
	sta	DEATHS		; for initials
	mvi	B,3		;number of chars
	mvi	C,'A'
S.L:	push	b
	lda	FLIP		;0 or 8=flop
	call	SHOWC
	pop	b
	mvi	0(y),15
..wlp:	call	NEXT.J
	mov	a,0(y)
	ora	a
	jrnz	..wlp
T.L:	mvi	0(y),60		;sixty ticks to a second
I.L:	mov	a,0(y)		;if a second is up
	ora	a
	jrnz	I.S
	lda	DEATHS		;then if[[--wait.time]==0]
	dcr	a
	sta	DEATHS
	jrz	BUP		;leave else goto t.l
	jmpr	T.L
I.S:	call	S.STICK
	bit	4,A		;fire:lock in letter?
	jrz	ROTA
	mov	m,c		;store
	push	b		;save number of letters
	lda	FLIP
	ora	a
	lxi	b,64		;shift down 2 lines
	jrz	..up
	lxi	b,-64
..up:	push	d
	xchg
	dad	b
	xchg
	lda	FLIP		;0 or 8=flop
	ori	90H		;xor
	mvi	C,'_'		;erase underline
	call	SHOWC
	pop	d
	pop	b
	inx	h		;point to next letter
	lda	FLIP
	ora	a
	inx	d		;move screen position
	jrz	..dl
	dcx	d		;backwards writing
	dcx	d
..dl:	call	S.STICK
	bit	4,A
	jrnz	..dl
	djnz	S.L		;dec chars left
; update battery backed up score
BUP:	lxi	h,HIGH1
	lxi	d,HIGH2
	lxi	B,(5*6<8)!0
BHLP:	mov	a,m
	ani	0F0h
	stax	d
	inx	d
	add	c		;check sum it on fly
	mov	c,a
	mov	a,m
	inx	h
	rlc
	rlc
	rlc
	rlc
	ani	0F0h
	stax	d
	inx	d
	add	c		;check sum it on fly
	mov	c,a
	djnz	BHLP
	mov	a,c		;get xsum
	sta	HIGH2-1		;store it
	ret
; change letter?
ROTA:	bit	0,A		;down,left=less
	jrnz	..su
	bit	3,A
	jrnz	..su
	bit	1,A		;up/right=more
	jrnz	..ad
	bit	2,a
	jrnz	..ad
	jmp	I.L
..su:	mvi	a,-1
	jmpr	..adj
..ad:	mvi	a,1
..ADJ:	add	c		;change char
	cpi	'A'-1		;check in range a-z
	jrnz	..2
	mvi	A,'Z'
..2:	cpi	'Z'+1
	jrnz	..3
	mvi	A,'A'
..3:	mov	c,a		;store new char
	jmp	S.L
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Add A to 2 nibble in books
; c=carry status
;______________________________
AdBtoN: push	psw
	rlc
	rlc
	rlc
	rlc
	call	Nib
	pop	psw
;	call	Nib
Nib:	ani	0f0h
	exaf
	mov	a,m
	ani	0f0h
	add	c
	daa
	mov	m,a
	exaf
	add	m
	daa
	mov	m,a		;store the books
	dcx	h
	mvi	c,0
	rnc
	mvi	c,10h		;carry
	ret
;---------------
ELine1: WROTE	90H,32,08,("Congratulations Player ")
	ret
FLine1: WROTE	90H,16,08,("Felicitations au joueur ")
	ret

GLine1: WROTE	90H,32,08,("Gratuliere, Spieler ")
	ret
SLine1: WROTE	90H,32,08,("Felicitaciones jugador ")
	ret
;---------------
ELine2: WROTE	90H,08,32,("You have joined the immortals")
	WROTE	90H,16,48,("in the FRENZY hall of fame")
	WROTE	90H,24,80,("Enter your initials:")
	ret
FLine2: WROTE	90H,08,32,("Vous avez joint les immortels")
	WROTE	90H,24,48,("du pantheon FRENZY.")
	WROTE	90H,08,80,("Inscrire vos initiales:")
	ret
; ----------------------	123456789012345678901234567890
GLine2: WROTE	90H,08,32,("Das War ein Ruhmvoller Sieg!")
	WROTE	90H,08,64,("Trag Deinen Namen in die")
	WROTE	90H,16,80,("Heldenliste ein!")
	ret
SLine2: WROTE	90H,04,32,("Se puntaje esta entre los diez")
	WROTE	90H,08,48,("mejores.")
	WROTE	90H,24,80,("Entre sus iniciales:")
	ret
;---------------
GLine3	==	.
ELine3: WROTE	90H,8,128,("Move stick to change letter")
	WROTE	90H,8,144,("then press FIRE to store it.")
	ret
FLine3: WROTE	90H,4,128,("Poussez batonnet pour vos")
	WROTE	90H,4,144,("initiales. Poussez FIRE quand")
	WROTE	90H,4,160,("lettre correcte")
	ret
;
SLine3: WROTE	90H,4,128,("Moviendo la palanca para")
	WROTE	90H,4,144,("cambiar las letras, luego")
	WROTE	90H,4,160,("aplaste el boton de disparo")
	WROTE	90H,4,176,("para retenerlas.")
	ret

	.end

