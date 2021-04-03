B>type init.asm

.title	"INTERRUPT ROUTINE"
.sbttl	"FRENZY"
.ident	INT
;--------------------
; interrupt routine
;--------------------
.insert equs
.intern INT,PLOT
.extern RtoA
;---------------------------------------
; this routine does writing, erasing,
; moving, and pattern animation based
; on the following structure
;	---- v.stat	vector status	<- IY points here
;	---- setup	last magic value
;   -------- o.a.l/h	old screen address
;   -------- o.p.l/h	last pattern addr.
;	---- tprime	value to stuff into time
;	---- time	time til move
;	---- v.x	x velocity
;	---- v.y	y velocity
;	---- p.x	x position
;	---- p.y	y position
;   -------- d.p.l/h	pattern pointer
;--------------------------------------
INT:	out	NMIOFF		;turn off nmi's
	di			;believe it [cuz of calls]
	push	psw
	in	WHATI		;bottom of screen?
	rar			;test bit 0
	jrc	BS		;skip if middle of screen
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Middle of Screen Interrupt
;_______________________________
; use only AF,BC,HL
	out	NMION		;prob get nmi immed'ly
	push	h		;save em
	push	b
	lxi	h,SWD		; check coins
	mov	a,m		;oldset switch
	inx	h
	mov	b,m		;old sw.
	xra	b		;difference in a
	mov	c,a		; in c
	in	I.O2		;new sw.s
	cma
	mov	m,a		;store new switch
	dcx	h
	mov	m,b		;make old->oldest
	ana	c		;check new=1 old=1 oldest=0
	ani	0c0H
..lp:	dcx	h		;->cackle
	bit	7,a		; check bit
	jrz	..sk
	inr	m		;inc coin counter
..sk:	add	a		;shift bits
	jrnz	..lp
; update man alternator
	lxi	h,Man.Alt
	srlr	m
;take care of seconds counter
	lxi	h,T60cnt
	dcr	m
	jp	..ous
	mvi	m,60		;reset seconds timer
	mvi	c,8		;inc total seconds in backgnd
	call	ItemInc#	;pushes all reg used
	lda	DEMO
	ora	a
	mvi	c,7		;total game time
	cz	ItemInc
	lxi	h,KWait		;adjust kill off
	mov	a,m
	ora	a
	jrz	..ous
	dcr	a
	mov	m,a
..ous:	call	GetC#		;if no credits
	mvi	L,0
	ora	a		;skip to waiter
	jrz	I.but
	cpi	1		;if only one credit
	mvi	L,1		;then check only button1
	jrz	I.but
	mvi	L,3
I.but:	in	I.O2		;check start button[s]
	cma
	ana	l
	mov	l,a		;save buttons
	lda	StartB		;previous buttons
	ora	l
	sta	StartB		;save for main
	jz	..exit
	bit	7,a		;in play flag
	jz	GO#		;go play NOW
..exit: pop	b
	pop	h
	jmp	BYE
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Bottom of Screen Interrupt
;_______________________________
BS:	push	y		;save old jobs
	push	x
	push	h
	push	d
	push	b
	exaf
	push	psw
;< do color man every 4 int?>
	lxi	h,0		;null vector pointer
	shld	OLD1
	shld	OLD2
	shld	OLD3
	lxi	h,Inttyp	;test alternator
	rlcr	m		;by rotating the bits
	mvi	b,3		;do 2 others if no man
	lhld	L.PTR		;robot list pointer
	jc	..ilp
	lxi	h,Vectors
	shld	Old3		;save for updates
	call	SECT1		;rewrite man
	call	UNCMAN#		;uncolor man
	lxi	h,Vectors
	bit	COLOR,m		;do color
	cnz	COLMAN#
	lhld	L.PTR		;robot list pointer
	mvi	b,2		;# of robots to do
..ilp:	push	b
	call	SECT1		;rewrite robot
	pop	b
	lhld	V.PTR		;Get vector pointer
; save pointer for later update
	xchg
	mov	a,b		;get index
	add	a		;double
	lxi	h,Old1-2	;save array start
	add	l		;add b*2 to hl
	mov	l,a
	mov	a,h
	aci	0
	mov	h,a
	mov	m,e		;store vector address
	inx	h		;for later update
	mov	m,d
	xchg
..inc:	lxi	d,VLEN		;delta to next vector
	dad	d		;point to next
	lxi	d,Vectors+(MaxVec*VLEN) ;end of list
	mov	a,l		;see if at end
	cmp	e
	jnz	..tst
	mov	a,h
	cmp	d
	jz	..end
..tst:	mov	a,m		;see if vector is on
	ani	(1<INUSE)
	jrz	..inc		;if not look at another
	djnz	..ilp
	jmp	..done
..end:	lxi	h,Vectors+VLEN	;first non-man vector
..done: shld	L.PTR		;next one to look at
	call	BUL.V#		;rewrite & vector bolts
; now that bolts have done hitting things
; update Vectors (coordinates)
	lhld	OLD3		;first vector written
	call	SECT3
	lhld	OLD2
	call	SECT3
	lhld	OLD1		;last vector written
	call	SECT3		;update animation and vector
	call	TIMERS		;do job timers
	pop	psw		;restore all registers
	exaf
	pop	b
	pop	d
	pop	h
	pop	x
	pop	y
BYE:	mvi	A,1		;turn on interrupts
	out	I.ENAB
	out	NMION		;prob get nmi immed'ly
	mvi	A,ITAB/256
	stai
	im2
	pop	psw
	ei
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; all below assume iy -> vector
;	and [v.ptr]=iy
;----------------
; erase pattern
;________________
SECT1:	shld	V.PTR
	liyd	V.PTR
	bit	ERASE,M		;hl->v.stat
	jz	SECT2
	res	ERASE,M		;never erase more than once
	inx	h		;->setup
	mov	a,m		;get old magic value
	out	MAGIC
	inx	h		;->old address
	mov	e,m
	inx	h		;->o.a.h
	mov	d,m
	inx	h		;->old pattern
	mov	a,m		;hl:=[hl]
	inx	h		;->o.a.h
	mov	h,m
	mov	l,a
	call	PLOT		;xor write
	lhld	V.PTR
;----------------
; write pattern
;----------------
SECT2:	bit	WRITE,M		;check if should write
	rz
	res	WRITE,M		;never write twice either
	lxi	d,P.X
	dad	d		;->p.x
	mov	e,m		;x position
	inx	h		;->v.y
	inx	h		;->p.y
	mov	d,m		;y position
	inx	h
	mvi	B,90H		;xor write
	xchg
	call	RtoA
	mov	SETUP(y),A	;save magic
; get pattern address := @pattern.pointer
	xchg
	mov	a,m		;->d.p.l
	inx	h
	mov	h,m		;->d.p.h
	mov	l,a
	mov	a,m		;get word in table
	inx	h		;which ->pattern
	mov	h,m
	mov	l,a
; check for offset pattern
	inx	h		;->y
	mov	a,m
	dcx	h
	bit	7,A
	jrz	..noo		;normal non offset
	ani	7FH
	mov	b,a
	mov	c,m
	inx	h
	inx	h
	xchg
	lda	FLIP
	ora	a
	jz	..down
	dsbc	b
	.byte	(3eh)		;mvi a,(dad b)
..down: dad	b
	xchg
; store pattern away
..noo:	mov	O.P.L(y),L
	mov	O.P.H(y),H
	mov	O.A.L(y),E	;save screen address
	mov	O.A.H(y),D
	call	PLOT
	lhld	V.PTR
; check intercept
	in	WHATI
	bit	7,A		;nz means 1 writtn over 1
	rz
	set	INEPT,M		;set intercept bit
	ret			;no point in moving object
;--------------------------
; move position, animate
;--------------------------
SECT3:	shld	V.PTR
;	bit	Color,m 
;	cnz	COLMAN#
	bit	MOVE,M		;should be moved?
	rz
	push	h
	pop	y		;iy->vector
; MOVE bit reset by routine that set it
	lxi	d,TPRIME
	dad	d		;->tprime
	mov	a,m
	inx	h		;->time
	dcr	m		;dec time,if0 then
	rnz
	mov	m,a		;time:=tprime
; vector in x
	inx	h		;->V.X
	mov	a,m
	inx	h		;->p.x
	add	M
	mov	m,a
;vector y
	inx	h		;->v.y
	mov	a,m
	inx	h		;->p.y
	add	M
	mov	m,a
; update pattern [animate]
	inx	h		;->d.p.l
	mov	e,m
	inx	h		;->d.p.h
	mov	d,m		;get table address
	inx	d
	inx	d		;point to next entry
	xchg
	mov	a,m		;if0 then
	inx	h
	ora	m		;jump
	jnz	..sk
	inx	h		;get pointer
	mov	a,m		; to value of next word
	inx	h
	mov	h,m
	mov	l,a		;->head of table
	.byte	(3eh)		;mvi a,dcx h (7 T not 12)
..sk:	dcx	h
	xchg			;de=table address
	mov	m,d		;hl->d.p.h
	dcx	h
	mov	m,e		;->d.p.l
	mvi	A,(1<Write)!(1<Erase)
	lhld	V.Ptr
	ora	M		;or with V.STAT
	mov	M,A
	ret
;-----------------------
; decrement job timers
;-----------------------
TIMERS: lxi	h,Timer0
	mvi	b,24
..loop: mov	a,m
	ora	a
	jrz	..dl
	dcr	m
..dl:	inx	h
	djnz	..loop
	ret
;-------------------------------
; write pattern with intercept
; 2 byte wide routine	
;-------------------------------
;hl->pattern	de->screen data
PLOT:	mvi	B,0		; bc=pattern x size
	mov	a,m
	inx	h
	dcr	a
	jz	X1PLOT		;if not 1 then 2 bytes only!
	lda	FLIP
	ora	a		;check flip state
	mov	a,m		; y size
	inx	h
	jnz	XF2PLT
	lxi	b,Hsize-2
	xchg			;de->pattern byte
Y.LOOP: exaf			;save y size
	ldax	d		;get pattern byte
	inx	d		;->next pattern byte
	mov	m,a		;write to screen
	inx	h
	ldax	d		;repeat for next byte
	inx	d
	mov	m,a
	inx	h
	mov	m,b		;flush shifter(b=0)
	exaf
	dad	b		;hl->next line of screen
	dcr	a		;--y.size
	jnz	Y.LOOP
	ret
;-----------------------------------------
; two byte wide upside-down plot routine
;-----------------------------------------
XF2PLT: lxi	b,2-Hsize
	xchg			;de->pattern byte
Y.Lp:	exaf			;save y size
	ldax	d		;get pattern byte
	inx	d		;->next pattern byte
	mov	m,a		;write to screen
	dcx	h
	ldax	d		;repeat for next byte
	inx	d
	mov	m,a
	dcx	h
	mvi	M,0		;flush shifter(b=0)
	exaf
	dad	b		;hl->next line of screen
	dcr	a		;--y.size
	jnz	Y.Lp
	ret
;-----------------------------
; one byte wide plot routine
;-----------------------------
;hl->pattern	de->screen data
X1PLOT: lda	FLIP		;hl->y size
	ora	a		;check flip state
	mov	a,m		;load y size
	inx	h		;->first data byte
	jnz	XF1PLT
	lxi	b,Hsize-1
	xchg			;de->pattern byte
..loop: exaf			;save y size
	ldax	d		;get pattern byte
	inx	d		;->next pattern byte
	mov	m,a		;write to screen
	inx	h
	mov	m,b		;flush shifter(b=0)
	exaf
	dad	b		;hl->next line of screen
	dcr	a		;--y.size
	jnz	..loop
	ret
;-----------------------------------
; flipped 1 byte wide plot routine
;-----------------------------------
XF1PLT: lxi	b,1-Hsize
	xchg			;de->pattern byte
..loop: exaf			;save y size
	ldax	d		;get pattern byte
	inx	d		;->next pattern byte
	mov	m,a		;write to screen
	dcx	h		;backwards writing
	mvi	M,0		;flush shifter(b=0)
	exaf
	dad	b		;hl->next line of screen
	dcr	a		;--y.size
	jnz	..loop
	ret
BYTE2:: .byte	0
;------------------
; interrupt table
;------------------
	.loc	3FFCH

ITAB:	.word	INT		;video
BYTE4:: .word	0		;xsum

	.loc	4000h
	.word	BYTE1#
	.word	BYTE2
	.word	BYTE3#
	.word	BYTE4
	.word	BYTE5#

	.end
