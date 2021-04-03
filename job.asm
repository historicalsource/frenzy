B>type job.asm

.title	"Job Scheduling"
.sbttl	"FRENZY"
.ident JOBS
;~~~~~~~~~~~~~~~~~~~~
; multi-job System
;____________________
.insert EQUS
.extern Zap
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Job System Initialization
;____________________________
JobInit::
	xra	a		;reset man alternator
	sta	Man.Alt
	lxi	h,J.Used
	lxi	b,(MaxJob*JobLength)+2
	jmp	Zap
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Pass Control to next job
;____________________________
Next.J::
	push	y		;pc is on stack
	push	x		;save all registers
	push	h
	push	d
	push	b
	push	psw		;->job store area
	call	JobPtr		;returns in de
	lxi	h,0
	dad	sp		;hl->top of stack(the register set)
	lxi	b,JobLength	;move stack to store
	LDIR
	lxi	h,J.Used	;move to next job
	mov	b,m		;# in use
	inx	h		;->J.Index
..loop: mov	a,m
	inr	m		;++J.Index
	cmp	b		;see if we're last job
	jrnz	..ok
	mvi	m,0
..ok:	mov	a,m		;is it man job
	cpi	1		;if so skip it
	jrz	..loop
	lxi	h,Man.Alt	;check if time for man job
	mov	a,m
	ora	a
	jrnz	OK1
	mvi	m,1b		;reset alternator
	lda	J.Used		;check number of jobs used
	ora	a
	jrz	OK1		;no man job yet so skip
	call	MJPtr		;->man job
	jmpr	GOJ
OK1:	call	JobPtr
GOJ:	lxi	h,SPos-JobLength
	sphl			;->stack area
	xchg
	lxi	b,JobLength	;move store to stack
	LDIR
	pop	psw		;get this job's registers
	pop	b
	pop	d
	pop	h
	pop	x
	pop	y
	ret			;and pc register too
;~~~~~~~~~~~~~~~~~~~~~~
; Return from man job
;______________________
Man.Next::
	push	y		;pc is on stack
	push	x		;save all registers
	push	h
	push	d
	push	b
	push	psw		;->job store area
	call	MJPtr		;returns -> man job in de
	lxi	h,0
	dad	sp		;hl->top of stack(the register set)
	lxi	b,JobLength	;move stack to store
	LDIR
	jmp	OK1		;go do next job
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Split off new job
;____________________________
J.FORK::
	push	b		;bc=starting PC for new job
	push	y		;also get set of input
	push	x		;registers for parms
	push	h
	push	d
	push	b
	push	psw
; check if possible to start a new job
	lxi	h,J.Used	;-># of jobs in use (0 is 1)
	mov	a,m
	cpi	MaxJob-1
	jrc	..ok
	lxi	h,7*2		;sorry no room
	dad	sp		;get rid of registers
	sphl
	stc			;aborto
	ret
;ok to add a job
..ok:	inr	m		;++J.Used
	call	JLPtr		;get pointer to last job in de
	lxi	h,0
	dad	sp		;top ot stack frame
	lxi	b,JobLength
	LDIR
	pop	psw		;restore mother registers
	pop	b
	pop	d
	pop	h
	pop	x
	pop	y
	pop	b		;was copy of bc=daughter pc
	ora	a		;nc means no problem
	ret			;return to mother
;~~~~~~~~~~~~~~~~~~~~
; Delete Current Job
;____________________
JobDel::
	lxi	h,J.Used
	mov	a,m		;save
	dcr	m		;one less job active
	inx	h		;->J.Index
	sub	m		;J.Used-J.Index
	jrnz	..move		;if = then this is last job
	mvi	m,0		;reset J.Index
..go:	call	JobPtr		;de->frame
	jmpr	GOJ
..move:			;move jobs up j.index stays same
	call	JobPtr		;de->frame
	lxi	h,JobLength
	dad	d		;hl->next frame
	xchg
	push	h
	lxi	h,Jobs+(MaxJob*JobLength) ;->end of job area
	ora	a
	dsbc	d		;hl=#of bytes to end of job area
	mov	b,h
	mov	c,l
	pop	h
	xchg
	LDIR
	jmpr	..go
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Point to Job[J.Index] Storage Area
;_____________________________________
MJPtr:	mvi	c,1
	.byte	(3eh)		;mvi a,(mov c,m)
JLPtr:	mov	c,m
	lxi	h,Jobs
	jmpr	JP2
JobPtr: lxi	h,J.Index
	mov	c,m		;current index
	inx	h		;->Jobs
JP2:	mvi	b,0
	xchg
	lxi	h,0		;hl=14*bc (J.Index*JobLength)
	MULT	JobLength
	dad	d		;Jobs[Jindex*JobLength]
	xchg			;return de->job area
	ret
;~~~~~~~~~~~~~~~~~~~~~~~
; Initialize the Timers
;_______________________
TimerInit::
	lxi	h,Talloc	;timer allocation area
	lxi	b,MaxTimer+(Maxtimer/8)
	jmp	Zap
;~~~~~~~~~~~~~~~~~~
; Allocate a Timer
;__________________
; returns hl->a timer byte
GetTimer::
	push	d
	push	b
	push	psw
	lxi	h,Talloc
	lxi	b,(MaxTimer/8)<8 ;#of timers:timer0
..alp:	mov	a,m		;get alloc bits
	cpi	-1		;if not all 1's
	jrnz	..get		;then find a zero bit
	mvi	a,8		;move index up 8
	add	c
	mov	c,a
	inx	h		;->talloc group
	djnz	..alp		
..bad:	pop	psw
	stc			;no timer available
	jmpr	..ret
..get:	mvi	b,1		;bit 0 mask
..blp:	mov	d,a		;save Talloc
	ana	b		;check bit
	mov	a,d		;restore Talloc
	jrz	..ok
	inr	c		;up the index
	rlcr	b		;move bit left
	jmpr	..blp
..ok:	ora	b		;set alloc bit
	mov	m,a		;set Talloc
	mvi	b,0		;bc=timer #
	lxi	h,Timer0
	dad	b		;hl->special timer
	pop	psw
	ora	a
..ret:	pop	b
	pop	d
	ret
;~~~~~~~~~~~~~~~
; Free a Timer
;_______________
; input hl->timer byte
FreeTimer::
	push	b
	push	psw
	mvi	m,0
	lxi	b,Timer0	;find the offset
	ora	a
	dsbc	b		;hl=timer number
	mov	a,l
	cpi	24
	jrnc	..ret
	lxi	h,Talloc	;->talloc[0..7]
..idx:	cpi	8		;check index 0..7
	jrc	..ok
	inx	h		;->talloc[+8]
	sui	8		;index-=8
	jmpr	..idx
..ok:	mvi	b,#1		;FEh bit 0 negitive mask
	ora	a		;index=0?
	jrz	..fr
..blp:	rlcr	b		;move bit mask up
	dcr	a		;dec index
	jrnz	..blp
..fr:	mov	a,b
	ana	m
	mov	m,a	
..ret:	pop	psw
	pop	b
	ret
;~~~~~~~~~~~~~~~~~~
; Put job to sleep
;__________________
; input A=number of 60ths to wait
J.WAIT::
	pop	y
	call	GetTimer
	mov	m,a
..lp:	call	NEXT.J
	mov	a,m
	ora	a
	jrnz	..lp
	call	FreeTimer
	pciy

	.end
