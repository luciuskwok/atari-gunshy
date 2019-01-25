; tile.asm 

.include "atari_memmap.inc"
.include "global.inc"


.rodata 

blankTile:
	.byte $00,$00,$00,$00,$01,$55,$55,$80,$01,$55,$55,$A0,$01,$55,$55,$A0
	.byte $01,$55,$55,$A0,$01,$55,$55,$A0,$01,$55,$55,$A0,$01,$55,$55,$A0
	.byte $01,$55,$55,$A0,$01,$55,$55,$A0,$02,$AA,$AA,$20,$00,$AA,$AA,$80
	.byte $00,$00,$00,$00
	blankTileHeight = 13 	; lines
	blankTileLength = blankTileHeight*4 

tileMaskShift0:
	.byte $C0,$00,$03,$FF
	.byte $00,$00,$00,$FF
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $00,$00,$00,$3F
	.byte $C0,$00,$00,$3F
	.byte $F0,$00,$00,$3F

tileMaskShift2:
	.byte $F0,$00,$00,$FF
	.byte $C0,$00,$00,$3F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $C0,$00,$00,$0F
	.byte $F0,$00,$00,$0F
	.byte $FC,$00,$00,$0F

tileMaskShift4:
	.byte $FC,$00,$00,$3F
	.byte $F0,$00,$00,$0F
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $F0,$00,$00,$03
	.byte $FC,$00,$00,$03
	.byte $FF,$00,$00,$03

tileMaskShift6:
	.byte $FF,$00,$00,$0F
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FC,$00,$00,$00
	.byte $FF,$00,$00,$00
	.byte $FF,$C0,$00,$00


layerPixelOffset:
	.byte 70, 90
	.byte 42, 74
	.byte 34, 58
	.byte 26, 42
	.byte 13, 36

boardCenterX: .byte 72
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
	.import fillMemoryPages
	.import pusha
	.import _tileLayers
	.import _tileApex
	.import _layerSize
	.import _fontPage

	; Fill the screen with $FF
	ldx _fontPage 
	ldy #7*4
	lda #$FF 
	jsr fillMemoryPages

	tileRow = OLDROW 
	tileCol = OLDCOL
	tileLvl = OLDCOL+1
		lda #0
		sta tileLvl

	layer = ptr2 
	tileIndex = tmp4 

	loop_level:
		ldx tileLvl 
		lda _tileLayers,X
		sta layer 
		lda _tileLayers+1,X 
		sta layer+1

		lda #0
		sta tileIndex
		sta tileRow 
		loop_row:
			ldx tileLvl 
			lda #0
			sta tileCol 
			loop_col:
				ldy tileIndex 
				lda (layer),Y 
				beq next_col

				pha ; tile value
				jsr tileLocationInternal

				pla ; tile value
				jsr _drawTile
			next_col:
				inc tileIndex
				lda tileCol 
				clc 
				adc #1
				sta tileCol 
				ldx tileLvl 
				cmp _layerSize,X ; layerSize[level].x: layer width
				bne loop_col 
		next_row:
			lda tileRow 
			clc 
			adc #1 
			sta tileRow 
			ldx tileLvl 
			cmp _layerSize+1,X ; layerSize[level].y: layer height
			bne loop_row
	next_level:
		lda tileLvl 
		clc 
		adc #2
		sta tileLvl 
		cmp #10
		bne loop_level 

	rts
.endproc 

; void tileLocation(uint8_t level, uint8_t row, uint8_t col);
.export _tileLocation
.proc _tileLocation
	.import popa 

	col = OLDCOL
		sta col 

	row = OLDROW
		jsr popa 
		sta row 

	level = OLDCOL+1
		jsr popa 
		asl a
		sta level 

	jmp tileLocationInternal
.endproc 

.proc tileLocationInternal
	; on entry:
	; OLDROW: tile row
	; OLDCOL: tile col
	; OLDCOL+1: tile level
	; returns location in pixels in ROWCRS, COLCRS
	.import mulax10 ; uses ptr1

	tileCol = OLDCOL 
	tileRow = OLDROW
	tileLvl = OLDCOL+1 ; tileLvl = level * 2

	; col = tileCol * 10 + boardCenter.x
	lda tileCol 
	ldx #0
	jsr mulax10
	clc 
	adc boardCenterX
	sta COLCRS 

	; row = tileRow * 20 + boardCenter.y
	lda tileRow
	asl a 
	ldx #0
	jsr mulax10
	clc 
	adc boardCenterY
	sta ROWCRS

	; offset = layerPixelOffset[level]
	ldx tileLvl

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
		lda tileCol
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
			lda tileRow
			cmp #4
			bne skip_second_to_last
				lda ROWCRS
				sec 
				sbc #10
				sta ROWCRS
				jmp skip_right_endcap
			skip_second_to_last:
			cmp #5
			bne skip_last
				lda ROWCRS
				sec 
				sbc #30
				sta ROWCRS
				lda COLCRS
				clc 
				adc #10
				sta COLCRS
			skip_last:
		skip_right_endcap:
	skip_layer0:

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

		lda ROWINC 				; Output 2 lines for each 1 line in source
		and #$FE
		asl a 					; X steps by 4, ROWINC steps by 1
		tax 

		jsr _getTileMaskAtRow	; Get mask

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

		jsr _doBitShift

		; Apply mask and image to 5 colummns in unrolled loop
		ldy #0
		lda (SAVADR),Y 		; 5+1
		and maskTemp 		; 4
		ora imageTemp	 	; 4
		sta (SAVADR),Y		; 6 

		ldy #8
		lda (SAVADR),Y 		; 5+1
		and maskTemp+1 		; 4
		ora imageTemp+1	 	; 4
		sta (SAVADR),Y		; 6 

		ldy #16
		lda (SAVADR),Y 		; 5+1
		and maskTemp+2 		; 4
		ora imageTemp+2	 	; 4
		sta (SAVADR),Y		; 6 

		ldy #24
		lda (SAVADR),Y 		; 5+1
		and maskTemp+3 		; 4
		ora imageTemp+3	 	; 4
		sta (SAVADR),Y		; 6 

		ldy #32
		lda (SAVADR),Y 		; 5+1
		and maskTemp+4 		; 4
		ora imageTemp+4	 	; 4
		sta (SAVADR),Y		; 6 

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

.export _getTileMaskAtRow
.proc _getTileMaskAtRow
	; sets maskTemp data, with X = row * 4, SHFAMT = bit shift

	lda SHFAMT 
	cmp #6
	bcs shift_6_bits 
	cmp #4
	bcs shift_4_bits
	cmp #2
	bcs shift_2_bits

	no_shift:
		lda tileMaskShift4,X
		sta maskTemp 
		lda tileMaskShift4+1,X
		sta maskTemp+1
		lda tileMaskShift4+2,X
		sta maskTemp+2
		lda tileMaskShift4+3,X
		sta maskTemp+3
		lda #$FF
		sta maskTemp+4
		rts 
	shift_2_bits:
		lda tileMaskShift6,X
		sta maskTemp 
		lda tileMaskShift6+1,X
		sta maskTemp+1
		lda tileMaskShift6+2,X
		sta maskTemp+2
		lda tileMaskShift6+3,X
		sta maskTemp+3
		lda #$FF
		sta maskTemp+4
		rts 
	shift_4_bits:
		lda #$FF
		sta maskTemp
		lda tileMaskShift0,X
		sta maskTemp+1 
		lda tileMaskShift0+1,X
		sta maskTemp+2
		lda tileMaskShift0+2,X
		sta maskTemp+3
		lda tileMaskShift0+3,X
		sta maskTemp+4
		rts 
	shift_6_bits:
		lda #$FF
		sta maskTemp
		lda tileMaskShift2,X
		sta maskTemp+1 
		lda tileMaskShift2+1,X
		sta maskTemp+2
		lda tileMaskShift2+2,X
		sta maskTemp+3
		lda tileMaskShift2+3,X
		sta maskTemp+4
		rts 
.endproc

.export _doBitShift
.proc _doBitShift
	; on entry: shiftArea has bits to shift, SHFAMT the number of times to shift right
	.rodata 
	shift2RightA:

	shift2RightB:


	.code 

	ldy SHFAMT 
	jmp next_shift
	loop_shift:
		lsr imageTemp 	; 6
		ror imageTemp+1	; 6
		ror imageTemp+2	; 6
		ror imageTemp+3	; 6
		ror imageTemp+4	; 6
		dey  			; 2
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


; Unused?
.proc copyMemory 
	; on entry: Y = length, ptr2 = src, ptr1 = dest
	.importzp ptr1, ptr2 
	loop:
		dey 
		lda (ptr2),Y 
		sta (ptr1),Y 
		cpy #0
		bne loop 
	rts 
.endproc 
