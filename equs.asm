B>type equs.asm

.slist
.xlist
;last revision: 18-Jan-82
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Macros
;_______________________________
; multiply b*Num hl=0
.define MULT[Num]=[
.ifn Num-1,[	MULT	\(Num/2)
	dad	h
]
.ifn Num&1,[	dad	b
]]
.define WAIT[Time]=[
	mvi	a,time
	call	J.WAIT#
]
.define FORK[Addr]=[
	lxi	b,Addr
	call	J.FORK#
]
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	RAM equates
;_______________________________
Hsize	==	32		; bytes per line
Vsize	==	224		; lines of screen
BatteryRAM==	0F800H		; start of battery ram
Nibbles ==	0FA00H		; start of non-backed-up nibbles
VideoRAM==	4000h		; start of wait stated ram
ScreenRAM==	4400H		; beginning of screen ram
EndScreen==	5FFFH		; end of screen ram
MagicScreen==	ScreenRAM+2000H ; magic screen ram
ColorRAM==	8000H		; color ram start
ColorScreen==	8100H		; start-ram that colors screen
EndColor==	87FFH		; end of color ram
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	VFB IO ports
;_______________________________
I.O1	==	48H		; Switch ports
I.O2	==	49H
I.O3	==	4AH
MAGIC	==	4BH		; Shifter/flopper/alu control
NMION	==	4CH		; turns NMIs on
NMIOFF	==	4DH		; turns NMIs off
WHATI	==	4EH		; middle/bottom screen status
I.ENAB	==	4FH		; enable interrupts=-1
FLOP	==	3		; bit number
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	ZPU IO Ports
;_______________________________
DIP2	==	60H		; DIP switch bank
DIP1	==	61H
DIP3	==	62H
DIP4	==	63H
DIP5	==	64H
ZPU	==	65H		; push buttons bits 7&0
LED.OFF ==	66H		; turn LED off
LED.ON	==	67H		; turn LED on
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Vector Equates
;_______________________________
V.STAT	==	0
SETUP	==	1
O.A.L	==	2
O.A.H	==	3
O.P.L	==	4
O.P.H	==	5
TPRIME	==	6
TIME	==	7
V.X	==	8
P.X	==	9
V.Y	==	10
P.Y	==	11
D.P.L	==	12
D.P.H	==	13
VLEN	==	D.P.H+1		;length of vector
MaxVec	==	24
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	V_STAT bits
;_______________________________
ERASE	==	0		;see INT for documentation
WRITE	==	1
MOVE	==	2
BLANK	==	3
COLOR	==	4
INEPT	==	5		;for all hits
HIT	==	6		;for bolt hit
InUse	==	7
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Bolt Equates
;_______________________________
Bolts	==	7		;number of bolts
Blength ==	3+(6*2)		;length of entrys
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 Job Equates
;_______________________________
; saves AF,BC,DE,HL,IX,IY,PC
MaxJob	==	25
JobLength ==	2*(6+2)		;save 6 word regs+stack
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	 Man Colors
;_______________________________
M1color ==	0AAH
M2color ==	0EEH
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Battery Ram
;_______________________________
; 16 Bit Oriented section
; (in byte section because its the only ram with no wait states)

	.loc	BatteryRAM
	.blkb	80h
SPos	==	.		;OS (normal) stack
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Sound Chip Phantom Registers
;_______________________________
TCR1:	.blkb	1
TCR2:	.blkb	1
TCR3:	.blkb	1
TMR1:	.blkw	1
TMR2:	.blkw	1
TMR3:	.blkw	1
NOISE:	.blkb	1
VOL1:	.blkb	1
VOL2:	.blkb	1
VOL3:	.blkb	1
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Sound Interpreter Vars
;_______________________________
PC0:	.blkw	1
PC1:	.blkb	1		;priority of sound
WLSND:	.blkb	1		;non0 if a wall hit
RFSND:	.blkb	1		;non0 if reflected bolt
AC0:	.blkw	1
AC1:	.blkw	1
AC2:	.blkw	1
AC3:	.blkw	1
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Voice Vars
;_______________________________
V.PC:	.blkw	1		;voice pc
T.TMR:	.blkb	1		;time until next talk
CHIKEN: .blkb	1		;chicken flag
MemPhs: .blkb	1		;not used
PSave:	.blkb	1		;for bonus/percent store
Man.Alt:.blkb	1		;man alternator for when to do job
KWait:	.blkb	1		;time til kill off
Dcolor: .blkb	1		;square dot color
	.blkb	8		;filler
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	COLOR routines area
;_______________________________
Caddr:	.blkb	2		;address of last man write
Csave:	.blkb	2*6		;save/restore area
Wpoint: .blkb	1		;points for a wall hit
Wcolor: .blkb	1		;walls color
Rcolor: .blkb	1		;color of robots
Mcolor: .blkb	1		;man's color
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Vector area
;_______________________________
V.Ptr:	.blkw	1		;pointer to next vector
L.Ptr:	.blkw	1		;pointer to robot vector list
Old1:	.blkw	1		;addresses of vectors rewritten
Old2:	.blkw	1		; in this 
Old3:	.blkw	1		;  interrupt
IntTyp: .blkb	1		;alternater (55h)
T60cnt: .blkb	1		;second timer
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Book-keeping Data Area
;_______________________________
	.blkb	1		;xsum
CREDITS:.blkb	2
	.blkb	1		;xsum
Chute1: .blkb	8
	.blkb	1		;xsum
Chute2: .blkb	8
	.blkb	1		;xsum
Play1:	.blkb	6
	.blkb	1		;xsum
Play2:	.blkb	6
	.blkb	1		;xsum
Plays:	.blkb	6
	.blkb	1		;xsum
ScoreSum:.blkb	12
	.blkb	1		;xsum
PlayTime:.blkb	12
	.blkb	1		;xsum
OnTime: .blkb	12
	.blkb	1		;xsum
High2:	.blkb	5*12
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Screen RAM Data Area
;_______________________________
	.loc	VideoRAM
Temp:	.blkw	2		;buffer zone
NMIflg: .blkb	1		;used by powerup
PlayRet:.blkw	1		;return address for play
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Player Information Area
;_______________________________
Player: .blkb	1		;Player # of this player
RoomX:	.blkb	1		;room X position
RoomY:	.blkb	1		;room Y position
ManX:	.blkb	1		;copy of man position
ManY:	.blkb	1
Deaths: .blkb	1		;number of lives/deaths for player
Percent:.blkb	1		;Percentage factor for game
Rbolts: .blkb	1		;# of robot bolts
Rwait:	.blkb	1		;initial firing holdoff time
Stime:	.blkb	1		;super robot wait time
XtraMen:.blkb	1		;xtra man flags
RoomCnt:.blkb	1		;# of rooms exitted
; Other Player Info Area
Other:	.blkb	Other-Player	;Non playing persons records
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Misc area
;_______________________________
Robots: .blkb	1		;# of robots
Rsaved: .blkb	1		;saved # of robots
N.Plrs: .blkb	1		;# of players in this game
Flip:	.blkb	1		;flip screen=-1
IQflg:	.blkb	1		;-1 head toward man
SSpos:	.blkw	1	;super start position
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Walls Array
;_______________________________
Walls:	.blkb	4*6		;array of wall DURL bits by squares
	.blkb	4*6		;type array
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Coins Area
;_______________________________
StartB: .blkb	1		;start button tracker
Coins:	.blkb	2		;number of coins not counted yet
SWD:	.blkb	2		;switch trackers
;only need 1 byte for cackle
CACKLE: .blkb	3		;partial credit accumulators
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Demo Area
;_______________________________
Demo:	.blkb	1		;flag =-1 if in demo
SavedScore:.blkb 3		;saves player score
DemoPtr:.blkb	2		;-> fake control data
Seed:	.blkb	2		;random number seed
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Score Area
;_______________________________
WallPts: .blkb	1		;points for wall
UPDATE: .blkb	1		;has score been updated
Score1: .blkb	3		;player 1's score
Score2: .blkb	3		;player 2's score
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Interrupt Area
;_______________________________
HIGH1:	.blkb	6*10		;high score to date display
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Interrupt Area
;_______________________________
O.I.SP: .blkw	1		;old stack storage
M.COLOR:.blkb	1		;color of man
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Vector area
;_______________________________
Vectors:.blkb	MaxVec*VLEN	;area for vectors
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Job Area
;_______________________________
J.Used: .blkb	1		;# of jobs in use
J.Index:.blkb	1		;pointer to current job
Jobs:	.blkb	MaxJob*JobLength
VRend	==	.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Color Ram Area
;_______________________________
	.loc	ColorRam
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Timers Area
;_______________________________
MaxTimer==	24
Talloc: .blkb	MaxTimer/8
Timer0: .blkb	MaxTimer
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	Bolt Vectors
;_______________________________
BUL1:	.blkb	Bolts*Blength

	.loc	.PROG.
.rlist
