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

blankTile:
	.byte $00,$00,$00,$00,$15,$55,$5C,$00,$15,$55,$5F,$00,$15,$55,$5F,$00
	.byte $15,$55,$5F,$00,$15,$55,$5F,$00,$15,$55,$5F,$00,$15,$55,$5F,$00
	.byte $15,$55,$5F,$00,$15,$55,$5F,$00,$3F,$FF,$F3,$00,$0F,$FF,$FC,$00
	.byte $00,$00,$00,$00
blankTileMask:
	.byte $C0,$00,$03,$FF,$00,$00,$00,$FF,$00,$00,$00,$3F,$00,$00,$00,$3F
	.byte $00,$00,$00,$3F,$00,$00,$00,$3F,$00,$00,$00,$3F,$00,$00,$00,$3F
	.byte $00,$00,$00,$3F,$00,$00,$00,$3F,$00,$00,$00,$3F,$C0,$00,$00,$3F
	.byte $F0,$00,$00,$3F
	blankTileHeight = 13 	; lines
	blankTileLength = blankTileHeight*4 


layerPixelOffset:
	.byte 70, 90
	.byte 42, 74
	.byte 34, 58
	.byte 26, 42
	.byte 13, 36

boardCenterX: .byte 74
boardCenterY: .byte 90

.bss 
imageTemp: .res 5
maskTemp:  .res 5
.code 


; void drawTileBoard(void);
.export _drawTileBoard
.proc _drawTileBoard
	.importzp tmp1, tmp2, tmp3, tmp4
	.importzp ptr2
	.import _zeroOutMemory
	.import pushax, pusha
	.import _tileLayers
	.import _tileApex
	.import _layerSize
	.import _fontPage

	; Clear the screen
	lda #0 
	ldx _fontPage
	jsr pushax 
	lda #0
	ldx #7*4 ; 7 font blocks
	jsr _zeroOutMemory

	level = tmp1 
	lda #0
	sta level 

	row = tmp2 
	col = tmp3
	layer = ptr2 
	layerIndex = tmp4 


	loop_level:
		ldx level 
		lda _tileLayers,X
		sta layer 
		lda _tileLayers+1,X 
		sta layer+1

		lda #0
		sta layerIndex
		sta row 
		loop_row:
			ldx level 
			lda #0
			sta col 
			loop_col:
				ldy layerIndex 
				lda (layer),Y 
				iny 
				sty layerIndex 
				cmp #0
				beq next_col

				pha ; tile value
				lda level 
				lsr a
				jsr pusha 
				lda row 
				jsr pusha 
				lda col 
				jsr _tileLocation

				pla ; tile value
				jsr _drawTile
			next_col:
				lda col 
				clc 
				adc #1
				sta col 
				ldx level 
				cmp _layerSize,X ; layerSize[level].x: layer width
				bne loop_col 
		next_row:
			lda row 
			clc 
			adc #1 
			sta row 
			ldx level 
			cmp _layerSize+1,X ; layerSize[level].y: layer height
			bne loop_row
	next_level:
		lda level 
		clc 
		adc #2
		sta level 
		cmp #10
		bne loop_level 

	rts
.endproc 

; point_t tileLocation(uint8_t level, uint8_t row, uint8_t col);
.export _tileLocation
.proc _tileLocation
	.import popa 
	.import mulax10 ; uses ptr1

	; col = col * 10 + boardCenter.x
	sta OLDCOL 
	ldx #0
	jsr mulax10
	clc 
	adc boardCenterX
	sta COLCRS 

	; row = row * 20 + boardCenter.y
	jsr popa 
	sta OLDROW
	asl a 
	ldx #0
	jsr mulax10
	clc 
	adc boardCenterY
	sta ROWCRS

	; offset = layerPixelOffset[level]
	jsr popa 			; level
	asl a 
	tax 
	lda COLCRS
	sec
	sbc layerPixelOffset,X 	; col -= offset.x
	sta COLCRS 

	lda ROWCRS
	sec
	sbc layerPixelOffset+1,X	; row -= offset.y
	sta ROWCRS 

	; Special case for layer 0 far left and far right tiles
	cpx #0
	bne skip_layer0
		lda OLDCOL
		cmp #0 
		bne skip_left_endcap
			lda ROWCRS
			clc 
			adc #10
			sta ROWCRS
			jmp skip_layer0
		skip_left_endcap:
		cmp #13
		bne skip_right_endcap
			lda OLDROW
			cmp #3
			bne skip_second_to_last
				lda ROWCRS
				clc 
				adc #10
				sta ROWCRS
				jmp skip_right_endcap
			skip_second_to_last:
			cmp #4
			bne skip_last
				lda ROWCRS
				sec 
				sbc #10
				sta ROWCRS
				lda COLCRS
				clc 
				adc #10
				sta COLCRS
			skip_last:
		skip_right_endcap:
	skip_layer0:

	ldx ROWCRS 
	lda COLCRS
	rts 
.endproc 


.export _drawTile
.proc _drawTile
	; on entry: ROWCRS=y, COLCRS=x
	.import _setSavadrToCursor

	lda COLCRS 	; calculate SHFAMT: number of bits to shift right
	and #3 
	asl a 
	sta SHFAMT 

	; Draw blank tile
	lda #0
	sta ROWINC
	loop_line:
		jsr _getCursorAddr 

		ldx ROWINC 			; Get mask
		lda blankTileMask,X
		sta maskTemp 
		lda blankTileMask+1,X
		sta maskTemp+1
		lda blankTileMask+2,X
		sta maskTemp+2
		lda blankTileMask+3,X
		sta maskTemp+3
		lda #$FF
		sta maskTemp+4 

		lda blankTile,X		; Get image
		sta imageTemp 
		lda blankTile+1,X
		sta imageTemp+1
		lda blankTile+2,X
		sta imageTemp+2
		lda blankTile+3,X
		sta imageTemp+3
		lda #0
		sta imageTemp+4 

		jsr doBitShift

		ldx #0 				; Apply mask and image
		loop_col:
			txa 
			asl a 
			asl a 
			asl a 
			tay 

			lda (SAVADR),Y
			and maskTemp,X 
			ora imageTemp,X 
			sta (SAVADR),Y

			iny 
			lda (SAVADR),Y
			and maskTemp,X 
			ora imageTemp,X 
			sta (SAVADR),Y

			inx 
			cpx #5
			bne loop_col

		next_line:
			lda ROWCRS
			clc 
			adc #2
			sta ROWCRS

			lda ROWINC
			clc 
			adc #4
			sta ROWINC
			cmp #blankTileLength
			bcc loop_line


    rts ; remove after testing

    pha 
	jsr _setSavadrToCursor
	pla 
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

.proc doBitShift
	; on entry: shiftArea has bits to shift, SHFAMT the number of times to shift right
	ldy SHFAMT 
	jmp next_shift
	loop_shift:
		sec 
		ror maskTemp 
		ror maskTemp+1
		ror maskTemp+2
		ror maskTemp+3
		ror maskTemp+4
		lsr imageTemp 
		ror imageTemp+1
		ror imageTemp+2
		ror imageTemp+3
		ror imageTemp+4
		dey 
	next_shift:
		bne loop_shift 
	rts
.endproc 


.export _getCursorAddr
.proc _getCursorAddr
	; result is in AX and SAVADR
	.import _fontPage

	.rodata
	rowLookup:
		.word 0, 40*8, 80*8
		.word 1024*1, 1024*1 + 40*8, 1024*1 + 80*8
		.word 1024*2, 1024*2 + 40*8, 1024*2 + 80*8
		.word 1024*3, 1024*3 + 40*8, 1024*3 + 80*8
		.word 1024*4, 1024*4 + 40*8, 1024*4 + 80*8
		.word 1024*5, 1024*5 + 40*8, 1024*5 + 80*8
		.word 1024*6, 1024*6 + 40*8, 1024*6 + 80*8

	.code 

	lda ROWCRS
	lsr a 		; X = ROWCRS / 8 * 2 
	lsr a 
	and #$FE 
	tax 

	lda rowLookup,X 	; ptr1 = fontPage + rowLookup[X]
	sta SAVADR
	lda rowLookup+1,X
	clc 
	adc _fontPage
	sta SAVADR+1 

	lda ROWCRS 			; ptr1 += ROWCRS % 8
	and #7 
	clc 
	adc SAVADR 
	sta SAVADR  		; addition should not cross page boundary

	lda COLCRS 			; ptr1 += COLCRS / 4 * 8
	and #$FC			; There are 4 pixels per byte, so divide COLCRS by 4, 
	asl a 				; then multiply by 8 because there are 8 bytes per character.
	bcc skip_msb0
		inc SAVADR+1
	skip_msb0:
	clc 				; This is the same as masking off the lower 3 bits and 
	adc SAVADR			; multiplying by 2.
	sta SAVADR 
	bcc skip_msb1
		inc SAVADR+1
	skip_msb1:

	lda SAVADR 
	ldx SAVADR+1
	rts 
.endproc 
