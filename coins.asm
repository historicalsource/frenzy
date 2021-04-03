B>type coins.asm

.title	"Coins and credits"
.sbttl	"FRENZY"
.ident COINS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Coins Subroutines
;_______________________________
.insert equs
.intern CREDS,GetC,COINCK
.intern DECCRD
.extern SHOWN,GO,ItemInc,S.Free
ItemOffset	== 0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Wait for Coins
;----------------------------
; B=number of seconds to hang around
COIN0:: mvi	B,5
COIN1:: call	GetTimer#	;returns in HL
..Coin:
	mvi	M,30		;set timer to 30/60's or 1/2 second
..Fast:
	push	h		;save timer
	call	FreeCred	;check for service switch
	call	COINCK		;check coins
	jnz	GO		;if a button down GO play
	pop	h		;->timer
	mov	a,M		;check if timer still going
	ora	a
	jrnz	..Fast
	djnz	..Coin		;one less second to wait
	call	FreeTimer#
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 Display Credits
;--------------------------------------
CREDS:
	push	h		;create a 2 byte string on the stack
	lxi	h,0		;get its address into hl
	dad	sp
	call	GetC		;a:=credits
	mov	m,a		;store into 1st byte of stack
	mvi	B,2		;# of digits to show
	lxi	d,213*256+120	;where to show
	call	SHOWN		;show number
	pop	h		;remove temp from stack
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Get Credits into A
;--------------------------------------
GetC:
	lda	CREDITS+1	;load low nibble of credits
	rrc			;which is in high nibble
	rrc			;battery ram
	rrc			;into low nibble of A
	rrc
	ani	0FH		;mask off trash
	mov	c,a		;save low nibble
	lda	CREDITS		;get high nibble
	ani	0F0H		;mask trash
	ora	c		;or in low nibble
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Increment Credits by 1
;--------------------------------------
IncCred:
	call	GetC
	cpi	99H
	rz	
	ADI	1
	daa
	jmpr	PutCred
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Decrement Credits by 1
;--------------------------------------
DECCRD:
	call	GetC		;get credits
	ADI	99H		;add -1 in 9's complement arithmetic
	daa			;decimal adjust
	jmpr	PutCred		;store credits
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Put Credits in A into Battery RAM
;--------------------------------------
PutCred:
	push	b
	sta	CREDITS		;store in high nibble battery ram
	mov	c,a
	rlc			;rotate nibble
	rlc			;note-I dont mask extra bits here
	rlc			;but in getcred I do
	rlc
	sta	CREDITS+1	;store
	ani	0f0h
	add	c
	ani	0f0h
	sta	CREDITS-1	;xsum
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Convert Coin-Clicks to Credits
;--------------------------------------
; HL->coins for chute[x]
; C = i/o port with coin setting dips for chute[x]
; B = 2,1
ClickToCredit:
	in	DIP5		;credit amount
	ora	a
	jrnz	..pay
	push	b
	push	h
	mvi	b,1		;give a credit
	jmpr	..lp		;jump into loop
..pay:	mov	a,m		;check coin clinks
	ora	a		;if no clinks
	rz			; leave
	push	b		;save i/o port
	push	h		;save pointer to clinks thru chute
	dcr	m		;do one clink
	PUSH	B
	mov	a,b		;get chute number
	ADI	ItemOffset	;add offset
	mov	c,a		;pass in C to
	call	ItemInc		;do book-keeping
	POP	B
	pop	h		;restore pointer to clinks
	push	h
	mvi	b,-1		;no credits yet(adds one
	in	DIP5		;credit amount
	mov	e,a		;in E
	lxi	h,CACKLE	;move to fractional coins
	inp	A		;get dips
	add	m		;get fractional
..cr:	inr	b		;got enough for a credit
	mov	m,a		;store remaining credits
	sub	e		;subtract credit amount
	jrnc	..cr		;do another cred
	mov	a,b		;check credits
	ora	a
	jrz	..sk		;no creds-exit
..lp:	call	IncCred		;add a credit
	djnz	..lp		;b=number to add
..sk:	pop	h
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check Coins and Show New Credits
;--------------------------------------
COINCK: push	b
	lxi	h,Coins		;check coins
	call	GetC		;get credits
	push	psw
	lxi	b,DIP3!(2<8)	;2 dip banks
ChuteLoop:
	call	ClickToCredit	;clinks to credits
	inx	h
	inr	c
	djnz	ChuteLoop
	call	GetC		;if new credits
	pop	b		; aren't
	cmp	b		;  equal to old
	cnz	CREDS		;  then show em
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Check for Free Credit Button
;-------------------------------
FreeCred:
	call	S.Free
	rz	
	call	IncCred
..lp:	call	S.Free
	jrnz	..lp
	ret

	.end
