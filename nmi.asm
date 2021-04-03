B>type nmi.asm

.title	"Non-Maskable Interrupt"
.sbttl	"FRENZY"
.ident NMI
;------------------------+
; Non-Maskable Interrupt |
;------------------------+
.insert EQUS
CR1	==	40H
VOICE	==	44H
;------------------------+
; Non-Maskable Interrupt |
;------------------------+
NMI::
;	push	psw		;done at 66h
	push	b
	push	d
	push	h
	call	S.BOOK#		;CHECK CLEAR BUTTON
	jnz	BOOKS#
	lda	demo
	ora	a
	jrz	..ok
	mvi	a,1
	sta	TCR1
	jmp	..no
..ok:	call	SCPU		;0=NORMAL
..no:	call	C.LOAD
; Do voice if not demo
	lda	Demo
	ora	a
	jrnz	..stop
	lhld	V.PC		;GET VOICE PC
..lop:	mov	a,h		;IF 0 SKIP
	ora	l
	jrz	..exit
	in	VOICE		;IF BUSY SKIP
	ani	0C0H
	cpi	40H
	jrnz	..exit
	mov	a,m		;GET DATA
	bit	7,A		;IF NEGATIVE SKIP
	jrnz	..stop
	inx	h
	out	VOICE		;OUTPUT THE DATA
	bit	6,A		;IF A WORD
	jrz	..exit		; WAIT A 60TH
	jmp	..lop		;DO ANOTHER BYTE
..stop: lxi	h,0		;STOP TALKING
..exit: shld	V.PC		;STORE POINTER
	pop	h
	pop	d
	pop	b
	pop	psw
	out	NMION
	retn
;--------------------------------------+
; OUTPUT DATA TO ALL REGISTERS FROM RAM
; DO CONTROL REGISTERS
;
C.LOAD: lxi	h,TCR1		;->CR1 TRACKER
	mov	b,m
	inx	h
	mov	d,m
	inx	h
	mov	e,m
	inx	h
	mvi	c,CR1+1		;->CR2
	res	0,B		;ALL COUNTERS GO
	set	0,D		;SELECT CR1
	OUTP	D		;2
	dcr	c		;->C1:2
	OUTP	B		;1
	inr	c		;->C2
	res	0,D		;SELECT CR3
	OUTP	D		;2
	dcr	c		;->C1:3
	OUTP	E		;3
;DO TIMERS
T.LOAD: inr	c
	inr	c		;->MSB BUFFER
	mvi	B,3
	mov	a,c		;SAVE MSB PORT ADDRESS
	inr	c		;->LSB LATCH #1
	mov	d,c		;SAVE LSB PORT ADDRESS
T.LOOP: mov	e,m		;GET LSB DATA
	inx	h
	mov	c,a
	mov	a,m
	inx	h
	OUTP	A
	mov	a,c
	mov	c,d
	OUTP	E
	inr	d
	inr	d		;->LSB LATCH#N+1
	djnz	T.LOOP
;DO NOISE AND VOLUMES
V.LOAD: dcr	c		;->NOISE/VOLUME PORT
	mvi	A,0		;BITS6,7 FOR SELECT=NOISE
	mvi	B,4		;NUMBER OF REGISTERS
V.LOOP: ora	m		;OR IN DATA[BETTER BE GOOD]
	inx	h		;->NEXT REGISTER DATA
	OUTP	A		;OUTPUT
	ani	0C0H		;SELECT NEXT REGISTER
	ADI	40H
	djnz	V.LOOP
	ret
.PAGE
.title	"SOUNDS AND MACROS"
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Sound Process
;_______________________________
SCPU::	lda	RFSND
	ora	a
	cnz	RSND
	lda	WLSND
	ora	a
	cnz	WSND
	lhld	PC0		;get where we left off
	mov	A,H		;if 0 don't do anything
	ora	L
	rz
	PCHL			;goto routine
; stop completely
$STOP:	lxi	h,0
	shld	PC0
	ret
; wait for next interrupt
$TICK:	pop	h		;get where it was
	shld	PC0		;save 
	ret			;back to nmi routine
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Sound Macros
;_______________________________
.slist
.xlist
.define STOP=[	jmp	$STOP
]
.define TICK=[	call	$TICK
]
.define BR[LABEL]=[	jmp	LABEL
]
.define SOB[ByteAdr,Label]=[
	lxi	h,ByteAdr
	dcr	m
	jnz	Label
]
.define MVIB[Value,Location]=[
	mvi	a,Value
	sta	Location
]
.define MVIW[Value,Location]=[
	lxi	h,Value
	shld	Location
]
.define ADIB[Value,Location]=[
	lxi	h,Location
	mov	a,m
	adi	Value
	mov	m,a
]
.define ADIW[Value,Location]=[
	lhld	Location
	lxi	d,Value
	dad	d
	shld	Location
]
.define MVIBM[Addr,V0,V1,V2,V3,V4,V5,V6,V7]=[
	lxi	h,Addr
	mvi	m,V0
	$XB	V1,V2,V3,V4,V5,V6,V7
]
.define $XB[V0,V1,V2,V3,V4,V5,V6]=[
.ifb	[V0],[.exit]
	inx	h
	mvi	m,V0
	$XB	V1,V2,V3,V4,V5,V6
]
.define MVIWM[Addr,V0,V1,V2,V3,V4,V5,V6,V7]=[
.ifb	[V0],[.exit]
	lxi	h,V0
	lhld	Addr
	MVIWM	\Addr+1,V1,V2,V3,V4,V5,V6,V7
]
.define QUIET=[
	lxi	h,0
	xra	a
	shld	TCR1
	sta	TCR3
	shld	NOISE
	shld	VOL2
]
.define SETUP[R1,R2,R3,$NOISE,$VOL1,$VOL2,$VOL3]=[
	lxi	h,TCR1
	mvi	m,R1
	inx	h
	mvi	m,R2
	inx	h
	mvi	m,R3
	lxi	h,NOISE
	mvi	m,$NOISE
	inx	h
	mvi	m,$VOL1
	inx	h
	mvi	m,$VOL2
	inx	h
	mvi	m,$VOL3
]
.define TIMERS[T1,T2,T3]=[
	lxi	h,T1
	shld	TMR1
	lxi	h,T2
	shld	TMR2
	lxi	h,T3
	shld	TMR3
]
.define START[Sound,Priority]=[
Sound:: push	psw
	lda	PC1		;now priority
	cpi	Priority	;new "
	jc	..load
	jz	..load
	pop	psw
	ret
..load: mvi	a,Priority
	sta	PC1
	push	h
	lxi	h,$'Sound
	shld	PC0
	pop	h
	pop	psw
	ret
$'Sound:
]
.rlist
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Sounds
;_______________________________
NoSnd:: push	psw
	push	h
	QUIET
	xra	a
	sta	PC1
	pop	h
	pop	psw
	ret

FAP:	QUIET
	xra	a		;zap priority
	sta	PC1
	STOP

START	SFIRE,10
	SETUP	92H,92H,92H,0,5,6,6
	TIMERS	50,50,50
	MVIB	50,AC0
..2:	TICK
	ADIW	15,TMR1
	ADIW	17,TMR2
	ADIW	16,TMR3
	SOB	AC0,..2
	MVIB	50,AC0
..3:	TICK
	ADIW	10,TMR1
	ADIW	13,TMR2
	ADIW	15,TMR3
	SOB	AC0,..3
	BR	FAP

START	SFRY,13
	SETUP	90H,90H,90H,0,6,7,7
	MVIB	16,AC0
	MVIW	230,TMR1
..1:	MVIWM	TMR2,20,10
	MVIB	20,AC1
..2:	TICK
	ADIB	5,TMR2
	ADIB	30,TMR3
	SOB	AC1,..2
	ADIB	-4,TMR1
	SOB	AC0,..1
	BR	FAP

START	SBLAM,11
	SETUP	82H,80H,80H,3,7,7,7
	TIMERS	1,1,5
	TICK
	MVIBM	TCR1,92H,90H,90H
	MVIB	55,AC1
..1:	MVIB	6,AC0
..2:	TICK
	SOB	AC0,..2
	ADIW	1,TMR1
	SOB	AC1,..1
	BR	FAP

START	SRFIRE,11
	SETUP	92H,92H,92H,0,6,6,7
	TIMERS	20,45,90
	MVIB	4,AC1
..1:	MVIB	80,AC0
..2:	TICK
	ADIW	8,TMR1
	ADIW	17,TMR2
	ADIW	47,TMR3
	SOB	AC0,..2
	SOB	AC1,..1
	BR	FAP

START	SXLIFE,12
	SETUP	92H,92H,92H,0,7,7,7
	TIMERS	200,60,40
	MVIB	20,AC1
..1:	MVIB	20,AC0
..2:	TICK
	ADIW	20,TMR1
	ADIW	6,TMR2
	ADIW	4,TMR3
	SOB	AC0,..2
	MVIB	20,AC0
..3:	TICK
	ADIW	-20,TMR1
	ADIW	-6,TMR2
	ADIW	-4,TMR3
	SOB	AC0,..3
	SOB	AC1,..1
	BR	FAP
;rick O'shay sound
RSND:	xra	a
	sta	RFSND		;clear flag
	sta	WLSND		;clear flag
	lda	PC1		;now priority
	cpi	11		;new "
	jc	..go
	jz	..go
	ret
..go:				;do the sound
	mvi	a,11
	sta	PC1
	SETUP	92H,92H,92H,0,7,7,7
	TIMERS	48,56,64
	ldar			;get refresh reg!
	ani	1fh
	sta	AC1
..1:	TICK
	lda	AC1
	ani	7
	jnz	..on	
	lxi	h,VOL1
	mov	a,m		;v1
	dcr	a
	mov	m,a		;v1
	inx	h
	mov	m,a		;v2
	inx	h
	mov	m,a		;v3
..on:	ADIB	6,TMR1
	ADIB	7,TMR2
	ADIB	8,TMR3
	SOB	AC1,..1
	BR	FAP

; Wall sound
WSND:	xra	a
	sta	WLSND		;clear flag
	lda	PC1		;now priority
	cpi	10		;new "
	jc	..go
	jz	..go
	ret
..go:				;do the sound
	mvi	a,10
	sta	PC1
	SETUP	82H,80H,80H,3,7,7,7
	TIMERS	1,1,2
	TICK
	MVIBM	TCR1,92H,90H,90H
	MVIB	55,AC1
..1:	TICK
	ADIB	1,TMR2
	ADIB	1,TMR3
	SOB	AC1,..1
	BR	FAP

	.end

