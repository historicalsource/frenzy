B>type iq.asm

.title	"WALL DETECTER AND AVOIDANCE CONTROL"
.sbttl	"FRENZY"
.ident IQ
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Intelligence
;_______________________________
.insert EQUS
; DURL refered to thru out this program stands for
; Down,Up,Right,Left bits in directions and wall encoding.
DOWN	==	3
UP	==	2
RIGHT	==	1
LEFT	==	0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Check walls and avoid them
;_______________________________
;a=new DURL, c=old DURL, ix->vector, iy->mans
IQ::	push	b		;save tracker
	push	d
	mov	l,D.P.L(x)	;get height thru
	mov	h,D.P.H(x)	;pattern pointer
	mov	e,m
	inx	h
	mov	d,m
	xchg
	mov	d,a		;save DURL	
	inx	h		;skip x bytes
	mov	a,m		;y lines (height)
	mov	c,a		;for down test
	srlr	a		;h/2
	adi	1		;(h/2)+2
	mov	e,a		;number of lines to test
	mov	h,P.Y(x)	;get current position
	mov	l,P.X(x)
; Regs: HL=YXpos, E=height, c=DURL to test
; Down tests
	bit	DOWN,d
	jz	..TU
	push	h
	mov	a,c		;height of pattern
	adi	3		;margin of error
	add	h		;offset to look
	mov	h,a		;at for wall color
	push	d
	mvi	e,5
	call	testx		;check for white below
	pop	d
	pop	h
	jz	..TR		;if ok check right,left
	res	DOWN,d		;else forget that direction
	jmp	..TR
;up tests
..TU:	bit	UP,d
	jz	..TR
	push	h
	mvi	a,-3
	add	h
	mov	h,a
	push	d
	mvi	e,5
	call	testx
	pop	d
	pop	h
	jz	..TR
	res	UP,d
;	jmp	..TR
;right tests
..TR:	bit	RIGHT,d
	jz	..TL
	push	h
	mvi	a,11
	add	l
	mov	l,a
	push	d
	call	testy
	pop	d
	pop	h
	jz	..done
	res	RIGHT,d
	jmp	..done
;left tests
..TL:	bit	LEFT,d
	jz	..done
	push	h
	mvi	a,-3
	add	l
	mov	l,a
	push	d
	call	testy
	pop	d
	pop	h
	jz	..done
	res	LEFT,d
;	jmp	..done
..done:
	mov	a,d		;final result DURL
	pop	d
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Test in X direction
;_______________________________
; input: h=Y, l=X, c=DURL
; output: Z if robot color in that box
Testx:
	dcr	l		;test -1 line
	inr	e
..x:	call	CheckBox
	rnz
	exaf			;save test results
	mov	a,l		;get x
	adi	2		;add 2
	mov	l,a
	exaf			;now return test results
	dcr	e		;number of times to look
	jnz	..x
	ret			;returns Z
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Test in Y direction
;_______________________________
; input: h=Y, l=X, c=DURL
; output: Z if robot color in that box
Testy:	dcr	h
	inr	e
..y:	call	CheckBox
	rnz
	exaf			;save test results
	mov	a,h		;get Y
	adi	2		;add 2
	mov	h,a
	exaf			;now return test results
	dcr	e		;number of times to look
	jnz	..y
	ret			;returns Z
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check pixel for use
;_______________________________
CheckBox:
	push	h		;save YX
	call	RtoAx#		;in hl out hl,a
	ani	0fh		;save shift&flop
	bit	Flop,a
	jz	..fl
	xri	0Fh		;flip flop and shift
..fl:	xri	07h		;reverse shift
	di			;using magic
	out	MAGIC
	res	5,h		;convert magic->normal addr
	mov	a,m		;get normal screen
	sta	TEMP+(1<13)	;magic scratch
	ei
	lda	TEMP		;normal scratch
	ani	1		;check it
	pop	h		;restore YX
	ret
;---------------+
; get durl bits |
;---------------+
; input: h=x l=y
; output: a=durl bits for room xy is in
; used by man,robot to check for others in square
WallIndex::
	mov	a,l		;get y position
	sui	8		;edge of first room
	mvi	e,0
	cpi	48		;1st row
	jrc	..sk
	mvi	e,6		;2nd row
	cpi	48*2
	jrc	..sk
	mvi	e,6*2		;3rd row
	cpi	48*3
	jrc	..sk
	mvi	e,6*3		;4th row
..sk:	mov	a,h		;x pos
	sui	8		;edge of first room
	dcr	e
..xlp:	sui	40		;room x width
	inr	e
	jrnc	..xlp
	xchg
	lxi	b,WALLS		;->walls array
	mvi	H,0		;add index
	dad	b
	mov	a,m		;get durl for room
	xchg
	ret

	.end
