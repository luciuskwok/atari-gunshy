; tile.asm 

.include "atari_memmap.inc"
.include "global.inc"


.rodata 

blankTile:
	.byte $00,$00,$00,$00,$01,$55,$55,$80,$01,$55,$55,$A0,$01,$55,$55,$A0
	.byte $01,$55,$55,$A0,$01,$55,$55,$A0,$01,$55,$55,$A0,$01,$55,$55,$A0
	.byte $01,$55,$55,$A0,$01,$55,$55,$A0,$02,$AA,$AA,$20,$00,$AA,$AA,$80
	.byte $00,$00,$00,$00
blankTileMask:
	.byte $FC,$00,$00,$3F,$F0,$00,$00,$0F,$F0,$00,$00,$03,$F0,$00,$00,$03
	.byte $F0,$00,$00,$03,$F0,$00,$00,$03,$F0,$00,$00,$03,$F0,$00,$00,$03
	.byte $F0,$00,$00,$03,$F0,$00,$00,$03,$F0,$00,$00,$03,$FC,$00,$00,$03
	.byte $FF,$00,$00,$03
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
	.importzp ptr1
	.import tileset
	.import _setSavadrToCursor

	tileFace = ptr1 
		sec  			; tile = (tile - 1) / 4 * 32
		sbc #1 
		and #$FC
		ldx #0
		stx tileFace+1
		asl a 
		rol tileFace+1
		asl a 
		rol tileFace+1
		asl a 
		rol tileFace+1
		clc 
		adc #<tileset
		sta tileFace 
		lda tileFace+1
		adc #>tileset 
		sta tileFace+1

	lda COLCRS 	; calculate SHFAMT: number of bits to shift right
	and #3 
	asl a 
	sta SHFAMT 

	; Draw blank tile
	lda #0
	sta ROWINC
	loop_line:
		jsr _getCursorAddr 

		lda ROWINC 			; Output 2 lines for each 1 line in source
		and #$FE
		asl a 				; X steps by 4, ROWINC steps by 1
		tax 

		lda blankTileMask,X	; Get mask
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
		lda blankTile+3,X
		sta imageTemp+3
		lda #0
		sta imageTemp+4 

		cpx #2*4
		bcc outside_part 
		cpx #9*4
		bcs outside_part 
		inside_part:
			lda ROWINC
			sec 
			sbc #4
			asl a 
			tay 
			lda (tileFace),Y 
			sta imageTemp+1
			iny 
			lda (tileFace),Y 
			sta imageTemp+2
			jmp end_outside_part 
		outside_part:
			lda blankTile+1,X	; Lines above or below face of tile
			sta imageTemp+1
			lda blankTile+2,X
			sta imageTemp+2
		end_outside_part:

		jsr doBitShift

		ldx #0 				; Apply mask and image
		ldy #0
		loop_col:
			lda (SAVADR),Y
			and maskTemp,X 
			ora imageTemp,X 
			sta (SAVADR),Y

			tya 
			clc 
			adc #8 
			tay 

			inx 
			cpx #5
			bne loop_col

		next_line:
			inc ROWCRS

			ldx ROWINC
			inx 
			stx ROWINC 
			cpx #blankTileHeight*2
			bcs return
			jmp loop_line

	return:
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
