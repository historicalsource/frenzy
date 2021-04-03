B>type showa.asm

.title	"SHOW ALPHABETIC"
.sbttl	"FRENZY"
.ident SHOWA
;-----------------
; string display
;-----------------
.insert EQUS
.extern CHARSET
;-----------------------------------
; show a string
; inline parms: x,y bytes
; followed by a string ending in 0
;-----------------------------------
SHOWA:: pop	h		; hl -> inline parms
	mov	b,m		; magic value
	inx	h
	mov	e,m		; load x
	inx	h
	mov	d,m		; load y
	inx	h
	xchg
	call	RtoA
	xchg
..lp:	mov	c,m		; get char
	res	7,C		; clear end of string indicator
	call	SHOWC		; show char
	mov	b,a		; save magic
	lda	FLIP
	ora	a
	jrnz	..1
	inx	d		; point to next char position
	jmpr	..2
..1:	dcx	d
..2:	inx	h		; point to next character
	mov	a,m		; test next character
	ora	a		; if zero
	mov	a,b
	jnz	..lp		; then loop
	inx	h		;return past
	pchl		; data bytes
;-------------------------------
; relative to absolute	
; in:	b=magic ,h=y,l=x
; out:a=magic+shift,hl=address
;-------------------------------
RtoAx:: mvi	B,90H		;xor write
RtoA::	lda	FLIP
	ora	a
	mvi	A,7
	jrnz	..flp
	ana	l
	ora	b
	out	MAGIC		; set magic register
	srlr	H
	rarr	L
	srlr	H
	rarr	L
	srlr	H
	rarr	L
	lxi	b,MagicScreen
	dad	b
	ret
;flipped version
..flp:	ana	l
	ora	b
	set	FLOP,A
	out	MAGIC		; set magic register
	srlr	H
	rarr	L
	srlr	H
	rarr	L
	srlr	H
	rarr	L
	mov	b,h
	mov	c,l
	lxi	h,Hsize*224+MagicScreen-1
	ora	a
	dsbc	b
	ret
;-------------------
; show a character
; in:	a=magic trash
;	c=char
;	hl->string
;	de->mscreen
;-------------------
VOFSET	==	3
CHARV	==	9
;
SHOWC:: push	h		; savestring pointer
	lxi	h,0
	mvi	B,0
	dad	b
	dad	h		; calc char offset
	dad	h
	dad	h
	dad	b
	lxi	b,CHARSET-(1FH*CHARV)
	dad	b		;hl->char data
	push	d
	push	psw
	xchg			;hl->screen
	lda	FLIP		;check for flipped state
	ora	a
	ldax	d		;test for lower case
	jrnz	FLIPD
	ora	a
	jp	..no
	lxi	b,Hsize*VOFSET
	dad	b		;decender offset
..no:	mvi	a,CHARV		;number of bytes high
	lxi	b,Hsize-1	; offset to next line
..lp:	exaf
	pop	psw
	push	psw
	di
	out	MAGIC
	ldax	d		;get data
	ani	7FH		;clear shift bit
	inx	d
	mov	m,a		;write to screen
	inx	h
	mvi	M,0		;flush magic register
	ei
	dad	b		;move down a line
	exaf
	dcr	a
	jnz	..lp
	pop	psw
	pop	d
	pop	h
	ret
;flipped version
FLIPD:	ora	a
	jp	..no
	lxi	b,-Hsize*VOFSET
	dad	b		;decender offset
..no:	mvi	a,CHARV		;number of bytes high
	lxi	b,-Hsize+1	; offset to next line
..lp:	exaf
	pop	psw
	push	psw
	di
	out	MAGIC
	ldax	d		;get data
	ani	7FH		;clear shift bit
	inx	d
	mov	m,a		;write to screen
	dcx	h
	mvi	M,0		;flush magic register
	ei
	dad	b		;move down a line
	exaf
	dcr	a
	jnz	..lp
	pop	psw
	pop	d
	pop	h
	ret
;-------------------------------
; show a number
; i:	b = number of digits
;	de= y and x postition
;	hl= address of bcd string
;	does a plop write	
;-------------------------------
SHOWN:: push	b		;save number of digits
	mvi	B,0		;plop write
	xchg
	call	RtoA		;convert xy to address
	xchg
	exaf			;save magic reg
	pop	b
SHOWO:: res	0,C		;zero suppress on
..loop: mov	a,b		;get count
	dcr	a		;if last digit-
	jrnz	..skip		; dont suppress it
	set	0,C		;dont zero suppress
..skip: mov	a,m		;get 2 bcd digits
	bit	0,B		;odd or even digit?
	jrnz	..no		;shift
	srlr	A		;top digit
	srlr	A		;into bottom
	srlr	A
	srlr	A
	dcx	h
..no:	inx	h
	ani	0FH		;isolate digit
	jrnz	..SUP		;if 0 check-
	bit	0,C		; for suppress
	jrnz	..2
	mvi	A," "		;suppress it
	jmpr	..dec
..SUP:	SET	0,C		;no more suppress
..2:	adi	90h		;hex to ascii trick
	daa
	adi	40h
	daa
..dec:	push	h
	push	b
	mov	c,a		;char into c
	exaf			;restore magic reg
	call	SHOWC		;display one digit
	exaf			;save magic
	pop	b
	pop	h
	lda	FLIP
	ora	a
	jrnz	..ss
	inx	d		; point to next char position
	jmpr	..xx
..ss:	dcx	d
..xx:	djnz	..loop
	ret

	.end
