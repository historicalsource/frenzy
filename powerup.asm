B>type powerup.asm

.title	"Powerup tests"
.sbttl	"FRENZY"
.ident	POWERUP
;----------------
; power up tests
;----------------
.insert EQUS
.extern MAIN,NMI,DSPSW,ALIGN
; locations NMIflg are scratch flags. they are cleared by the game
; when it starts up. NMIflg is used to select which nmi routine to run.

%Zero	==	.

.main.::
	nop		;this must be here for the sound processor
	di		;this is a good idea.
	xra	a
	out	NMIOFF
	stai
; test vfb signature analysis dip
	in	DIP1	;bottom dip bank
	bit	0,A
	jnz	VFBSA	;do vfb signature analysis if switch one closed
	bit	2,A
	jnz	DSPSW
	bit	3,A
	jnz	ALIGN
	lxi	x,ROMTST
	jmpr	D2

;MACROS
.define PCALL[ADR]=[
	lxi	x,.+4+3
	jmp	ADR
]

ROMNUM: .byte	4		;number of roms (not including utility)
RAMST:	.word	BatteryRAM	;start of battery backup ram
RAMS12: .word	Credits-BatteryRAM-2	;length of battery backup ram

; flash LED ring bell
D0:	lxi	b,00		;delay
DEL1:	dcr	c
	jrnz	DEL1
	djnz	DEL1
D1:	in	66H		;led on
D2:	mvi	A,1		;tone on
	lxi	b,0141H
	lxi	d,8247H
D3:	OUTP	B		; 01 to 41 or 51
	dcr	c
	OUTP	D		; 82 to 40 or 50
	inr	c
	inr	c
	OUTP	B		; 01 to 42 or 52
	inr	c
	OUTP	B		; 01 to 43 or 53
	inr	c
	inr	c
	inr	c
	OUTP	E		; 47 to 46 or 56
	mvi	C,51H
	dcr	a
	jrz	D3
	lxi	b,00		;delay
DEL2:	dcr	c
	jrnz	DEL2
	djnz	DEL2
	in	67H		;led off
	xra	a
	out	40H		;tone off
	out	50H		;tone off
	pcix
;-------------------
; place nmi in here
;-------------------
.blkb	66h-(.-%Zero)
.ifn	(.-%Zero)-66h,[.error /NMI Address/]
	out	NMIOFF
	push	psw	;don't change this without fixing nmi in file main
	lda	NMIflg
	ora	a
	jnz	NMIADD	; do test nmi
;	pop	psw	;done in nmi
	jmp	NMI

; ROM test
;this routine reads romnum from the first game rom.
;it tests the checksum in the first romnum game roms and flags an error
;if there is one. It checks the remaining game roms to see if they contain
;any zeros. if a rom does, it tests its checksum and flags an error if
;there is one. it tests the checksum of the utility rom and flags an error
;if necessary. If I=1 it goes to scrram if no error and to exclp if an error.
;e will equal
;1 error in game rom 6 [C000-Cfff]
;2		5 [3000-3Fff]
;3		3 [2000-2Fff]
;4		1 [1000-1Fff]
;80 error in utility rom [0-Fff]
;if i = 0 and there is an error it will halt if no error it will go to romrtn.
ROMTST:: mvi	E,4
	lxi	x,1000H
ROM1:	lxi	b,1000H		;bc = 4096
	mvi	H,0		;h = 0
	mvi	L,0FFH		;l = ff
ROM2:	mov	a,0(x)		;a = [ix]
	mov	d,a
	ana	l
	mov	l,a		;l = l and a
	mov	a,d
	add	H
	mov	h,a		;h = h + a
	inx	x		;ix = ix + 1
	dcr	c
	jrnz	ROM2
	djnz	ROM2		;loop 2048 times
	lda	ROMNUM
	cpi	0FFH		;bad system rom
	jrz	ROM5
	mov	a,E
	CPI	2
	JNZ	..
	LXI	X,0C000H
..:	ora	a
	jp	ROM3		;jmp if testing system rom
	mov	a,l		;test for empty socket
	inr	a
	jrz	ROM4		;jmp to rom4 if l = ff
ROM3:
;	mvi	A,0FFH
	mov	a,e		;get rom number
	cmp	h		;xsum = romnum?
	jrnz	ROM5		;jmp to rom5 if checksum <> ff
ROM4:	mov	a,e		;here if chksm = ff or empty socket
	rlcr	A		;contains all zeros
	jc	ROMRTN		;to romrtn if e = 80
	dcr	e		;e = e - 1
	jrnz	ROM1		;to rom1 if e <> 0
	ldai
	ana	a
	jnz	SCRRAM		;jump to scrram if in sa
	lxi	x,0		;ix = 0
	mvi	E,080H		;e = 80h
	jmpr	ROM1		;to rom1 to start new rom
ROM5:	ldai			;here if checksum error
	ana	a
	jnz	EXCLP		;to exclp if in sa
CKTRAP::			;halt if in powerup (cksum error)
	jmpr	.		;hang in the real system
;
ROMRTN: PCALL	D0		;in power up, ring bell & led
	jmp	SCRRAM
BYTE1:: .byte	0

; zpu sa loop
ZPUSA:	mvi	A,1
	stai			;i = 1
	jmp	ROMTST

; you get here by restarting with the sae connector in the test position
;	.loc	100H
.blkb	100h-(.-%Zero)
.ifn	(.-%Zero)-100h,[.error /100 Address/]
	jmpr	ZPUSA

; sa error execution loop
; e = one of the following numbers upon entering this routine
;e = 20 no ram or rom errors - - sa = 0
;e = 1	rom error 3800-3fff
;e = 2	rom error 3000-37ff
;e = 3	"	"	2800-2fff
;e = 4	"	"	2000-27ff
;e = 5	"	"	1800-1fff - - sa = 5220 VCC = 8A02
;e = 6	"	"	1000-17ff
;e = 10 ram error both nibbles - - sa = 6u6f
;e = 11 ram error low nibble - - sa = fa6p
;e = 12 ram error high nibble - - sa = ufp4
;the routine will loop forever and a signature corresponding
;to the value of e can be read on a13 with the rising edge of
; 0 as the clock and a15 as the start/stop signal
EXCLP:	lxi	b,08C0H
	lxi	h,0H
	mvi	D,8
RDLP:	mov	a,m	;read once from each rom and
	dad	b	;ram chip, write to ram chips
	xra	a
	star
	sta	1000H
	dcr	d
	jrnz	RDLP
	mvi	C,7FH	;c = 7f
	mvi	D,20H
INPLP:	mov	a,e
	ani	20H
	mov	b,a	;b = e and 20h
	inp	A	;input w.bit 5 of e on a13
	rrcr	E	;rotate e right
	dcr	c	;c = c - 1
	dcr	d
	jrnz	INPLP	;do it for c=7f to 60(ports on zpu board)
	mvi	A,80H
	lxi	b,8057H
OUTLP:	OUTP	A
	dcr	b
	dcr	c
	rrcr	A
	jrnc	OUTLP
	mvi	C,47H
OUTLP1: OUTP	A
	dcr	c
	rrcr	A
	jrnc	OUTLP1
	jmpr	EXCLP

;	scratch ram test
;
;this routine tests the scratchpad ram, starting at location ramst,
;and going to location ramst+rams12-1. ramst and rams12 are read from
;the first game rom. If I=1 then you are in sa and the routine goes
;to exclp with e = 20h if no errors, e = 12 if only errors in bits 4-7,
;e = 11 if only errors in bits 0 - 3, or e=10 if errors in both.
;if i = 0 then you are in game power up routine and it will halt if
;there are errors or go to ramt if no errors.
SCRRAM: lhld	RAMST
	lbcd	RAMS12
SCR1:	mvi	M,55H		;fill ram with 55 s
	dcx	h
	cci			;bc = bc - 1
	jpo	SCR2		;jump if bc=0
	inx	h		;hl = hl + 1
	jmpr	SCR1		;loop
SCR2:	mvi	D,0AAH
	lxi	sp,0FFFFH
SCR3:	lbcd	RAMS12		;bc = rams12
SCR4:	mov	a,d
	cma			;a = invert d
	xra	m
	jrnz	SCRERR		;jump if error
	mov	m,d		;[hl] = d
	dcx	h
	cci			;bc = bc - 1
	jpe	SCR6		;jump if bc <> 0
	mov	a,d
	cpi	55H
	jrz	SCR5		;to scr5 if d = 55h
	lxi	sp,1H		;sp = 1
	mvi	D,55H		;d = 55
	jmpr	SCR3
SCR6:	dad	sp		;hl = hl + sp
	jmpr	SCR4
SCRERR: mov	d,a
	ldai
	rrcr	A
	jrc	SCR7		;jump if in sa
	hlt			;halt if in power up
SCR7:	mvi	E,12H
	mov	a,d
	ani	0FH		;test for error in low nibble
	jz	EXCLP		;jmp w. e = 12 if no error
	dcr	e
	mov	a,d
	ani	0F0H		;test for error in high nibble
	jz	EXCLP		;jump w. e = 11 if no error
	dcr	e
	jmp	EXCLP		;jump w. e=10 if error in both
SCR5:	ldai
	rrcr	A
	mvi	E,20H
	jnc	RAMT		;to ramt if in game powerup
	jmp	EXCLP
;---------------------
; report ram errors Part of RAMTST
; bc=error bits
ERROR:	lxi	h,TABLE		;of screen addresses
	lxi	d,1		; test bit
CHECK:	mov	a,b		; bad ram bit?
	ana	d
	jnz	PLOT
	mov	a,c		; bad ram2 bit
	ana	e
	jmp	PLOT
RET1:	xchg
	dad	h		; shift test bit
	xchg
	jnc	CHECK
	lxi	d,4000H		; wait value
..wt:	dcr	e
	mov	a,0(y)		; waste time
	jnz	..wt
	dcr	d
	jnz	..wt
	jmp	RAMT2
;---------------+
; plot bad dips
;---------------+
PLOT:	exaf			; save whether good or bad
	mov	a,m		; get screen address word
	inx	h
	exx
	mov	l,a
	exx
	mov	a,m
	inx	h
	exx
	mov	h,a
	lxi	d,32-1		; offset to next line
	mvi	B,3		; number of notch lines
	exaf			; bad/good flag
ZORK:	ora	a
	jrz	GOOD1
	mvi	M,0FCH		; half of ic
	inx	h
	mvi	M,03FH		; second half
	jmpr	ON1
GOOD1:	mvi	M,84H		; first 1/2
	inx	h
	mvi	M,21H		; second 1/2
ON1:	dad	d		; goto next line
	djnz	ZORK
	mvi	B,36		; lines of body of ic
ZAP:	ora	a
	jrz	GOOD2
	mvi	M,0FFH
	inx	h
	mvi	M,0FFH
	jmpr	ON2
GOOD2:	mvi	M,80H
	inx	h
	mvi	M,01H
ON2:	dad	d
	djnz	ZAP
	exx
	jmp	ret1

;vfb signature analysis routine
;you get here by resetting with switch one of dip switch chip #26 closed
;	.loc	01fcH
.blkb	1fch-(.-%Zero)
.ifn	(.-%Zero)-1fch,[.error /1FC TITAB Address/]

TITAB:	.word	INTADD		;general interupts
	.word	BADINT		;general interupts with a bit stuck
;.=200
VFBSA:	lxi	b,1048H
	inp	A		;in from 48
	inr	c
	inp	A		;in from 49
	inr	c
	inp	A		;in from 4a
	inr	c
	inr	c
	inp	A		;in from 4c
	inr	c
	inp	A		;in from 4d
	inr	c
	inp	A		;in from 4e
	inr	c
	mvi	A,1
	OUTP	A		;out 01 to 4f
	lxi	b,0048H
	inp	A		;in from 48
	inr	c
	inp	A		;in from 49
	inr	c
	inp	A		;in from 4a
;this routine fully exercises the shifter,flopper, and intercept logic
;1.75 msec
	lxi	h,5000H
	lxi	d,7000H
	mvi	B,10H
VSA2:	mov	a,b
	dcr	a		;a = b - 1
	out	4BH		;output a to magic reg
	mvi	A,80H
VSA3:	mov	m,a		;write a to 5000h
	stax	d		;write a to 7000h
	mov	c,m
	rrcr	A
	jrnc	VSA3		;loop 8 times
	xra	a
	in	4EH		;input from intercept
	mvi	A,08H
	sta	5000H
	sta	7000H
	xra	a
	in	4EH
	inx	h
	inx	d
	djnz	VSA2		;loop 16 times
;this routine exercises all address bits to the ram and writes a pattern
;which can sa'ed at the serial video output
;228 usec
	mvi	B,0DH		;b = 13
	lxi	d,0A000H
	lxi	h,05FFEH
	mvi	A,80H		;a = 80
VSA1:	dcr	h
	mov	m,a		;[hl] = a write to ram
	mov	c,m		;c = [hl] read it back
	inr	h
	stc
	ralr	L
	ralr	H
	dad	d
	rrcr	A		;rotate a right
	djnz	VSA1		;loop 13 times
; fill bs color ram
	lxi	h,1111H
	lxi	d,1111H
	lxi	sp,8800H
	mvi	C,16
BS1:	mvi	B,16
BS2:	push	h
	push	h
	push	h
	push	h
	djnz	BS2
	dad	d
	pop	psw
	dcx	sp
	dcx	sp
	dcr	c
	jrnz	BS1
;----
	in	4CH	;turn on nmi
	xra	a
	in	4EH	;input interrupt feedback
	xra	a
	in	DIP1
	BIT	1,A
VSA6:	jrz	VSA6	;loop if not to do full test
;here to do full alu test
;you get here by closing switches 1,2 of dip switch pack 1
	lxi	h,5000H
	lxi	d,7000H
	mvi	A,0F0H
	stai			;i = f0h
VSA10:	lxi	b,004BH
	ldai
	OUTP	A		;output to magic reg
	mvi	C,0
VSA11:	mov	a,c
	mov	m,b		;write b to 5000h
	stax	d		;write c,a to 7000h
	mov	c,b
	cma
	mov	b,m		;read back from 5000h
	mov	b,a
	ora	c
	jrnz	VSA11
	ldai
	sui	10H
	stai			;i = i - 16
	jrnz	VSA10		;loop if i >= 0
VSA12:	jmpr	VSA12
;------------------------
; official vfb ram test
;------------------------
RAMT:	PCALL	D0		;ring bell & led
RAMT2:	lxi	h,5FFFH
	lxi	d,0
	PCALL	UPDN
	lxi	b,0		;clear error bits
	lxi	h,4000H		;start of ram
	PCALL	CELL.T		;test data lines
;do up down testing for address line problems
	lxi	h,4000H
	lxi	d,0055H
	PCALL	UPDN
	lxi	h,5FFFH
	lxi	d,55AAH
	PCALL	UPDN
	lxi	h,4000H
	lxi	d,0AAFFH
	PCALL	UPDN
	lxi	h,5FFFH
	lxi	d,0FF00H
	PCALL	UPDN
	mov	a,c
	ora	b
	jnz	ERROR
	PCALL	D0		;ring bell & led
;do color ram testing
	lxi	h,87FFH
	lxi	d,0
	PCALL	UPDN
	lxi	b,0		;clear error bits
	lxi	h,8000H		;start of 1kx4 ram
	PCALL	CELL.T		;test data lines
	lxi	h,8400H		;start of 1kx4 ram
	PCALL	CELL.T		;test data lines
;do up down testing for address line problems
	lxi	h,8000H
	lxi	d,0055H
	PCALL	UPDN2
	lxi	h,87FFH
	lxi	d,55AAH
	PCALL	UPDN2
	lxi	h,8000H
	lxi	d,0AAFFH
	PCALL	UPDN2
	lxi	h,87FFH
	lxi	d,0FF00H
	PCALL	UPDN2
	mov	a,c
	ora	b
..err:	jnz	..err
	lxi	x,SHFTST	;ring bell & led
	jmp	D0
;----------------------------------
; cell test for data line problems
;----------------------------------
CELL.T: mvi	D,0		; test value
C.LOOP: mov	m,d		; write test value
	mov	a,m		; read back
	xra	d		; check for bad bits
	ora	b		; add old bad bits
	mov	b,a		; save error bits
	inx	h		; test bank2
	mov	m,d
	mov	a,m
	xra	d
	ora	c
	mov	c,a
	dcx	h
	dcr	d		; new test value
	jnz	C.LOOP
	mvi	M,0
	inx	h
	mvi	M,0
	pcix
;--------------------------------------
; up down test for addressing problems
;--------------------------------------
UPDN2:	exx
	lxi	b,800H
	jmpr	UPDN3
;
UPDN:	exx
	lxi	b,2000H		; length of screen
UPDN3:	exx
D.LOOP: mov	a,m		; read old value
	xra	d		; set error bits
	ora	b		; add old errors
	mov	b,a		; save errors
	mov	m,e		; store new value
	mov	a,m		; test now
	xra	e		; check
	ora	b		; save errors
	mov	b,a
	bit	0,E		; test direction
	jnz	UP
	dcx	h
;	ld a,<dec hl> for timing considerations
	.byte	3Eh		; mvi a,next byte
UP:	inx	h
	mov	a,b		; swap b:c
	mov	b,c
	mov	c,a
	exx
	dcr	c
	jnz	D.E
	dcr	b
	jz	DONE
D.E:	exx
	jmp	D.LOOP
DONE:	exx
	mov	a,b		; swap b:c
	mov	b,c
	mov	c,a
	pcix
;-----------------------+
; table of ic locations
; arranged by bit number
; odd bank first
;-----------------------+
.define XY[PAR1,PAR2]=[
	.word	PAR1+PAR2+4400H
]
;
C1	==	9		;column xs
C2	==	C1+4
C3	==	C2+4
C4	==	C3+4
R1	==	0		;row ys
R2	==	50*32
R3	==	100*32
R4	==	150*32
;
TABLE:	XY	C2,R3		;o0
	XY	C2,R2		;o1
	XY	C2,R1		;o2
	XY	C2,R4		;o3
	XY	C4,R1		;o4
	XY	C4,R2		;o5
	XY	C4,R3		;o6
	XY	C4,R4		;o7
	XY	C1,R3		;e0
	XY	C1,R2		;e1
	XY	C1,R1		;e2
	XY	C1,R4		;e3
	XY	C3,R1		;e4
	XY	C3,R2		;e5
	XY	C3,R3		;e6
	XY	C3,R4		;e7
;------------------------------------------------
;this routine loops forever if there is an
;error in the shifter or flopper
;if no error it turns on the led and
;tone for 1/4 second then turns them off
;and goes to alutst
SHFTST: lxi	h,6000H		;magic ram address
	mvi	D,01H		;shift bit pattern
SHFT6:	mov	b,d		;b=shift bit pattern
	xra	a
	mov	c,a		;c=
	mov	e,a		;e=expected value
	stai			;i= magic value
SHFT5:	ldai
	out	4BH		;magic register = i
	mvi	M,0FFH		;prime HI
	mov	m,d		;6000h = d
	mvi	M,0		;6000h = 0
	mov	a,m		;get result
	cmp	e		;compare to expected
	jrnz	.		;error-loop forever
	ldai			;get magic value
	inr	a		;inc the shift
	stai			;store magic
	cpi	10H		;compare to legal range
	jrnz	SHFT1		;jump if .ne. 16
	ralr	D		;rotate left the bit pattern
	jrnc	SHFT6		; so try all patterns of one bit
	lxi	x,ALUTST	;go to next test
	jmp	D0		;delay, then to alutst

SHFT1:	mov	a,c		;rotate bc right
	rarr	A
	rarr	B		;bit pattern
	rarr	C
	mov	e,c		;e = c
	ldai			;check if floping
	cpi	8		;8=flop
	jrc	SHFT5		;if i<8 to shft5
	mvi	A,8		;this routine sets
SHFT4:	rrcr	B		;e = b flop
	ralr	E		;does not affect b
	dcr	a
	jrnz	SHFT4
	jmpr	SHFT5

;this routine loops forever if there is an
;error in the alu or interrcept logic
;if no error it turns on the led and
;tone for 1/4 second then turns them off
;and goes to inttst

ALUTST: mvi	E,0
	lxi	x,ALUSIM	;ix = alusim
	lxi	h,6000H		;hl = 6000
	lxi	b,0101H		;bc = 0101
ALU2:	mov	a,e
	out	4BH		;e to magic reg
	mov	a,b
	sta	4000H		;4000h = b
	mov	m,c		;6000h = c
	mov	a,c
	pcix		;simulate the alu
ALURET: xra	m		;xor simulation with [hl]
	jrnz	.		;loop if not equal
	mov	m,a		;(6000h) = 0
	mov	a,b
	ana	c
	jrz	ALU1
	mvi	A,80H
ALU1:	mov	d,a		;simulated intercept in bit 7 of d
	in	4EH
	xra	d
	ral
	jrc	.		;loop if intercept error
	rlcr	B		;rotate b and try again
	jrnc	ALU2
	rlcr	C		;rotate c and try again
	jrnc	ALU2
	inx	x
	inx	x
	inx	x
	mvi	A,10H		;update alu function
	add	E
	mov	e,a
	jrnc	ALU2
	lxi	x,INTTST
	jmp	D0		;delay then to inttst
;
ALUSIM: NOP			;0,a
	jmpr	ALURET
ALUOR:	ora	b		;1,a or b
	jmpr	ALURET
	cma			;2, (a + not(b)) , not(not(a) and +b)
	jmpr	ALUANC
	xra	a		;3, 1
	jmpr	ALUCMP
ALUAN:	ana	b		;4, a and b
	jmpr	ALURET
	mov	a,b		;5, b
	jmpr	ALURET
	xra	b		;6,not(a eor b)
	jmpr	ALUCMP
	cma			;7, not(a) or b
	jmpr	ALUOR
	cma			;8, (a and not(b)), not(not(a) or b)
	jmpr	ALUORC
	xra	b		;9, a eor b
	jmpr	ALURET
	mov	a,b		;10, not(b)
	jmpr	ALUCMP
ALUANC: ana	b		;11, not(a and b)
	jmpr	ALUCMP
	xra	a		;12, 0
	jmpr	ALURET
	cma			;13, not(a) and b
	jmpr	ALUAN
ALUORC: ora	b		;14, not(a or b)
	jmpr	ALUCMP
ALUCMP: cma			;15, not(a)
	jmpr	ALURET

;this routine loops forever if interupts or
;nmi does not work properly. if they are
;ok it turns the led and tone on for 1/4 second
;then turns them off and goes to gamst

INTTST	==	.
	IM2			;mode 2
	mvi	A,01	;table start
	stai			;point to 7fch
	lxi	x,MAIN
	mvi	A,0FFH
	out	4FH		;enable interupt
	mov	b,a
INTADD: lxi	sp,SCREEN-1	;give a stack pointer position
	in	4EH		;clear int
	rar
	ralr	B
	mov	a,b
	xri	55H
	jrz	NMITST
	ei
BADINT: jmpr	.

NMITST: out	4FH		;disable interupts
	mvi	B,0FFH
NMIADD: lxi	sp,SCREEN-1	;give a stack pointer position
	in	4DH		;disable nmi
	in	4EH		;read center/bottom screen
	rar
	ralr	B
	mov	a,b
	xri	020H
	jz	D0		;to delay if done
	in	4CH		;enable nmi
	jmpr	.

	.end
