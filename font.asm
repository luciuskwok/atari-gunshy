; font.s


.segment "FONT"

.export fontStart
fontStart:
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
.byte $FF,$FF,$FF,$FF,$FF,$FF,$00,$00
.byte $FC,$FC,$FC,$FC,$FC,$FC,$03,$03

.byte $00,$00,$55,$55,$55,$55,$55,$55
.byte $03,$03,$54,$54,$54,$54,$54,$54
.byte $55,$55,$55,$55,$55,$55,$55,$55
.byte $54,$54,$54,$54,$54,$54,$54,$54

.byte $00,$00,$55,$5F,$7F,$75,$D5,$D6
.byte $03,$03,$54,$D4,$F4,$74,$5C,$5C
.byte $DA,$DA,$D6,$D5,$75,$7F,$5F,$55
.byte $9C,$9C,$5C,$5C,$74,$F4,$D4,$54

.byte $00,$00,$5F,$75,$77,$77,$75,$5F
.byte $03,$03,$D4,$74,$74,$74,$74,$D4
.byte $55,$5F,$75,$77,$77,$75,$5F,$55
.byte $54,$D4,$74,$74,$74,$74,$D4,$54

.byte $00,$00,$5D,$77,$77,$5D,$55,$56
.byte $03,$03,$54,$54,$54,$54,$54,$54
.byte $59,$59,$56,$55,$55,$57,$57,$55
.byte $94,$94,$54,$54,$D4,$74,$74,$D4

.byte $00,$00,$55,$75,$DD,$DD,$75,$55
.byte $03,$03,$54,$64,$98,$98,$64,$54
.byte $55,$55,$65,$99,$99,$65,$55,$55
.byte $54,$54,$74,$DC,$DC,$74,$54,$54

.byte $00,$00,$55,$75,$DD,$DD,$75,$56
.byte $03,$03,$54,$74,$DC,$DC,$74,$54
.byte $59,$59,$56,$75,$DD,$DD,$75,$55
.byte $94,$94,$54,$74,$DC,$DC,$74,$54

.byte $00,$00,$75,$DD,$DD,$75,$55,$55
.byte $03,$03,$74,$DC,$DC,$74,$54,$54
.byte $65,$99,$99,$65,$65,$99,$99,$65
.byte $64,$98,$98,$64,$64,$98,$98,$64

.byte $00,$00,$75,$DF,$DD,$7D,$57,$55
.byte $03,$03,$54,$54,$F4,$DC,$DC,$74
.byte $65,$99,$99,$65,$65,$99,$99,$65
.byte $64,$98,$98,$64,$64,$98,$98,$64

.byte $00,$00,$55,$FD,$DD,$FD,$A9,$99
.byte $03,$03,$54,$FC,$DC,$FC,$A8,$98
.byte $A9,$FD,$DD,$FD,$A9,$99,$A9,$55
.byte $A8,$FC,$DC,$FC,$A8,$98,$A8,$54

.byte $00,$00,$76,$D9,$D9,$76,$55,$76
.byte $03,$03,$74,$9C,$9C,$74,$54,$74
.byte $D9,$D9,$76,$55,$76,$D9,$D9,$76
.byte $9C,$9C,$74,$54,$74,$9C,$9C,$74

.byte $00,$00,$55,$55,$55,$40,$55,$55
.byte $03,$03,$54,$54,$74,$04,$54,$54
.byte $55,$59,$6A,$59,$66,$5A,$66,$55
.byte $54,$94,$A4,$94,$64,$A4,$64,$A4

.byte $00,$00,$55,$50,$55,$55,$40,$55
.byte $03,$03,$54,$14,$54,$54,$04,$54
.byte $00,$00,$55,$50,$55,$50,$55,$40
.byte $03,$03,$54,$14,$54,$14,$54,$04

.byte $00,$00,$55,$40,$4D,$4D,$4D,$40
.byte $03,$03,$54,$04,$C4,$C4,$C4,$04
.byte $00,$00,$55,$40,$51,$40,$51,$40
.byte $03,$03,$54,$D4,$54,$14,$14,$04

.byte $00,$00,$55,$54,$40,$55,$51,$45
.byte $03,$03,$54,$54,$04,$54,$14,$44
.byte $00,$00,$55,$51,$50,$41,$51,$54
.byte $03,$03,$54,$44,$14,$54,$54,$14

.byte $00,$00,$55,$54,$55,$51,$51,$45
.byte $03,$03,$54,$54,$14,$14,$14,$04
.byte $00,$00,$55,$51,$40,$51,$51,$45
.byte $03,$03,$54,$54,$14,$14,$14,$04

.byte $00,$00,$55,$75,$FD,$5D,$5D,$75
.byte $03,$03,$54,$54,$54,$54,$54,$F4
.byte $7F,$7E,$7F,$5F,$55,$55,$55,$55
.byte $B8,$EC,$B4,$F4,$54,$54,$54,$54

.byte $00,$00,$55,$57,$57,$57,$57,$57
.byte $00,$00,$55,$56,$56,$56,$56,$56
.byte $55,$55,$57,$57,$57,$57,$57,$55
.byte $54,$54,$54,$54,$54,$54,$54,$54

.byte $00,$00,$55,$75,$75,$75,$75,$75
.byte $03,$03,$54,$74,$74,$74,$74,$74
.byte $55,$55,$75,$75,$75,$75,$75,$55
.byte $54,$54,$74,$74,$74,$74,$74,$54

.byte $00,$00,$55,$75,$75,$75,$76,$76
.byte $03,$03,$54,$74,$74,$74,$74,$74
.byte $56,$56,$76,$76,$75,$75,$75,$55
.byte $54,$54,$74,$74,$74,$74,$74,$54

.byte $00,$00,$55,$77,$77,$77,$77,$77
.byte $03,$03,$54,$74,$74,$74,$74,$74
.byte $55,$55,$77,$77,$77,$77,$77,$55
.byte $54,$54,$74,$74,$74,$74,$74,$54

.byte $00,$00,$55,$56,$56,$56,$55,$75
.byte $03,$03,$54,$54,$54,$54,$54,$74
.byte $75,$75,$55,$55,$75,$75,$75,$55
.byte $74,$74,$54,$54,$74,$74,$74,$54

.byte $00,$00,$55,$75,$77,$7F,$7D,$75
.byte $03,$03,$54,$74,$74,$F4,$F4,$74
.byte $55,$55,$75,$7D,$7F,$77,$75,$55
.byte $54,$54,$74,$F4,$F4,$74,$74,$54

.byte $00,$00,$55,$76,$76,$76,$55,$76
.byte $03,$03,$54,$74,$74,$74,$54,$74
.byte $76,$76,$55,$76,$76,$76,$55,$55
.byte $74,$74,$54,$74,$74,$74,$54,$54

.byte $00,$00,$55,$55,$55,$51,$51,$71
.byte $03,$03,$54,$54,$14,$14,$14,$34
.byte $51,$53,$51,$71,$51,$55,$55,$55
.byte $14,$14,$14,$14,$04,$54,$54,$54

.byte $00,$00,$55,$54,$5C,$40,$44,$40
.byte $03,$03,$54,$54,$D4,$04,$44,$04
.byte $44,$40,$54,$50,$44,$54,$55,$55
.byte $44,$04,$54,$14,$44,$54,$54,$54

.byte $00,$00,$55,$55,$40,$51,$51,$40
.byte $03,$03,$54,$54,$04,$14,$14,$04
.byte $4D,$4D,$4D,$40,$55,$55,$55,$55
.byte $C4,$C4,$C4,$04,$54,$54,$54,$54

.byte $00,$00,$55,$54,$50,$54,$40,$4D
.byte $03,$03,$54,$54,$14,$54,$04,$C4
.byte $44,$40,$4C,$44,$55,$55,$55,$55
.byte $44,$04,$C4,$44,$04,$54,$54,$54

.byte $00,$00,$55,$56,$56,$6A,$66,$66
.byte $03,$03,$54,$54,$54,$A4,$64,$64
.byte $6A,$56,$56,$56,$56,$55,$55,$55
.byte $A4,$54,$54,$54,$54,$54,$54,$54

.byte $00,$00,$55,$5F,$57,$5D,$5F,$77
.byte $03,$03,$54,$54,$54,$D4,$74,$D4
.byte $7F,$5D,$7F,$75,$55,$55,$55,$55
.byte $F4,$D4,$F4,$D4,$54,$54,$54,$54

.byte $00,$00,$55,$55,$5F,$5F,$77,$55
.byte $03,$03,$54,$54,$D4,$D4,$F4,$F4
.byte $55,$55,$55,$77,$5F,$5F,$55,$55
.byte $F4,$F4,$F4,$F4,$D4,$D4,$54,$54

.byte $00,$00,$55,$5A,$6B,$6E,$6B,$5A
.byte $03,$03,$54,$94,$A4,$E4,$A4,$94
.byte $57,$57,$57,$77,$5F,$57,$57,$55
.byte $54,$54,$54,$74,$D4,$54,$54,$54

fontEnd: 

.segment "FONT_HEAD"
	.word fontStart
	.word fontEnd-1
