; tile.asm 

.include "atari_memmap.inc"
.include "global.inc"


.rodata 

tileCharMap:
	.byte $88, $89, $8A, $8B ; 1 of discs
	.byte $8C, $8D, $8E, $8F ; 2 of discs
	.byte $90, $91, $92, $93 ; 3 of discs
	.byte $94, $95, $96, $97 ; 4 of discs
	.byte $98, $99, $9A, $9B ; 5 of discs
	.byte $9C, $9D, $9E, $9F ; 6 of discs
	.byte $A0, $A1, $A2, $A3 ; 7 of discs
	.byte $A4, $A5, $A6, $A7 ; 8 of discs
	.byte $A8, $A9, $AA, $AB ; 9 of discs
 
	.byte $2C, $2D, $2E, $2F ; 1 of chars
	.byte $30, $31, $2E, $2F ; 2 of chars
	.byte $32, $33, $2E, $2F ; 3 of chars
	.byte $34, $35, $2E, $2F ; 4 of chars
	.byte $36, $37, $2E, $2F ; 5 of chars
	.byte $38, $39, $2E, $2F ; 6 of chars
	.byte $3A, $3B, $2E, $2F ; 7 of chars
	.byte $3C, $3D, $2E, $2F ; 8 of chars
	.byte $3E, $3F, $2E, $2F ; 9 of chars

	.byte $40, $41, $42, $C3 ; 1 of bamboo
	.byte $44, $05, $46, $47 ; 2 of bamboo
	.byte $45, $05, $4A, $4B ; 3 of bamboo
	.byte $48, $49, $4A, $4B ; 4 of bamboo
	.byte $4C, $4D, $4E, $4F ; 5 of bamboo
	.byte $50, $51, $52, $53 ; 6 of bamboo
	.byte $54, $55, $56, $57 ; 7 of bamboo
	.byte $58, $59, $5A, $5B ; 8 of bamboo
	.byte $5C, $5D, $5E, $5F ; 9 of bamboo

	.byte $64, $65, $66, $67 ; East wind
	.byte $6C, $6D, $6E, $6F ; South wind
	.byte $68, $69, $6A, $6B ; West wind
	.byte $60, $61, $62, $63 ; North wind

	.byte $70, $71, $72, $73 ; Red dragon
	.byte $74, $75, $76, $77 ; Green dragon
	.byte $04, $05, $06, $07 ; White dragon

	.byte $F8, $F9, $FA, $FB ; Moon
	.byte $FC, $FD, $7E, $7F ; Flower

.code 

; void drawTile(uint8_t tile, uint8_t x, uint8_t y);
.export _drawTile
.proc _drawTile
	.import popa 
	.import _setSavadrToCursor

	sta ROWCRS 		; y
	jsr popa
	sec 
	sbc #1
	sta COLCRS 		; x
	jsr _setSavadrToCursor

	jsr popa 
	sec 
	sbc #1 
	and #$FC 		; mask out lower 2 bits to get offset into tileCharMap
	tax 

	ldy #1 			; draw upper half of face
	lda tileCharMap,X
	sta (SAVADR),Y 
	iny 
	lda tileCharMap+1,X 
	sta (SAVADR),Y 

	ldy #41 		; draw lower half of face
	lda tileCharMap+2,X
	sta (SAVADR),Y 
	iny 
	lda tileCharMap+3,X 
	sta (SAVADR),Y 

	ldy #81 		; draw front side of tile
	lda #$82
	sta (SAVADR),Y 
	iny 
	lda #$83
	sta (SAVADR),Y 

	ldy #0 
	lda (SAVADR),Y 
	bne skip_left0
		lda #1
		sta (SAVADR),Y 
	skip_left0:

	ldy #40 
	lda (SAVADR),Y 
	bne skip_left1
		lda #1
		sta (SAVADR),Y 
	skip_left1:

	ldy #80 
	lda (SAVADR),Y 
	bne skip_left2
		lda #1
		sta (SAVADR),Y 
	skip_left2:

	rts 
.endproc 
