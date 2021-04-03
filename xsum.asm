B>type xsum.asm

.title	"Xsums"
.sbttl	"FRENZY"
.ident	xsum
;----------------------------------------------------------------
;
;		CKSUM BYTE #1
;
;----------------------------------------------------------------
;
	.intern BYTE1,PRMNBR
	.extern BYTE2,BYTE3,BYTE4,BYTE5,BYTE6
;
BYTE1:		.byte	0	;SUM BYTE
;
;
;	NUMBER OF PROMS IN SYSTEM, DEFINES HERE	 IN POWERUP
;
PRMNBR	==	6
;
;
	.loc	4000H		;DATA TABLE FOR CKSUM GENERATING PROGRAM
	.byte	PRMNBR		;5 ROM SYSTEM
	.word	BYTE1
	.word	BYTE2
	.word	BYTE3
	.word	BYTE4
	.word	BYTE5
	.word	BYTE6
;
	.end
