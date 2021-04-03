B>type talk.asm

.title	"Talking"
.sbttl	"FRENZY"
.ident TALK
;--------------------------------
; voice synthesiser subroutines
;--------------------------------
.insert EQUS
; macros
; equates
XKILL	==	1
XATTACK ==	2
XCHARGE ==	3
XGOT	==	4
XSHOOT	==	5
XGET	==	6
XIS	==	7
XALERT	==	8
XDETECTED==	9
XTHE	==	10
XIN	==	11
XIT	==	12
XTHERE	==	13
XWHERE	==	14
XHUMANOID==	15
XCOINS	==	16
XPOCKET ==	17
XINTRUDER==	18
XNO	==	19
XESCAPE ==	20
XDESTROY==	21
XMUST	==	22
XNOT	==	23
XCHICKEN==	24
XFIGHT	==	25
XLIKE	==	26
XA	==	27
XROBOT	==	28
xp1	==29
xp2	==30
xp3	==31
;--------------------
; Talk Routines
;--------------------
Talk:	pop	h	;return points at talk
	SHLD	V.PC
	ret
S.TALK::
	call	talk
.byte	175Q,XROBOT,XATTACK,107Q,-1
SD.TALK::
	call	talk
.byte	176Q,XCHARGE,XATTACK,XSHOOT,XKILL,XDESTROY,107q,-1
F1.TALK::
	call	talk
.byte	174q,XA,Xrobot,Xis,Xnot,Xa,Xchicken,107q,-1
F2.TALK::
	call	talk
.byte	174q,Xa,Xrobot,Xmust,Xget,Xthe,Xhumanoid,107q,-1
M.TALK::
	call	talk
.byte	176q,Xthe,Xhumanoid,Xmust,Xnot,Xdestroy,Xthe,Xrobot,107q,-1
C.TALK::
	call	talk
.byte	173q,Xwhere,Xis,Xthe,Xhumanoid,107q,-1
;
PH1::	.byte	175Q,XCOINS,XDETECTED,XIN,XPOCKET
NoVoice::
	.byte	105Q,-1

	.end
