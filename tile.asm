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

layerOffset:
	.byte 14, 9
	.byte 8, 8
	.byte 6, 7
	.byte 4, 6
	.byte 1, 6

.code 


; void drawTileBoard(void);
.export _drawTileBoard
.proc _drawTileBoard
	.importzp tmp1, tmp2, tmp3, tmp4
	.importzp ptr1
	.import _zeroOutMemory
	.import pushax, pusha
	.import _tileLayers
	.import _tileApex
	.import _layerSize

	; Clear the screen
	lda SAVMSC 
	ldx SAVMSC+1
	jsr pushax 
	lda #<(RowBytes*20)
	ldx #>(RowBytes*20)
	jsr _zeroOutMemory

	level = tmp1 
	lda #0
	sta level 

	row = tmp2 
	col = tmp3
	layer = ptr1 
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

				dec COLCRS ; adjust for drawing code

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

	apex_tile:
		lda _tileApex 
		beq skip_show_border
			lda #PMLeftMargin+75
		skip_show_border:
		sta HPOSP3

	rts
.endproc 

; point_t tileLocation(uint8_t level, uint8_t row, uint8_t col);
.export _tileLocation
.proc _tileLocation
	.import popa 
	.import _boardCenter

	; col = col * 2 + boardCenter.x - layerOffset[level].x
	sta OLDCOL 
	asl a 
	clc 
	adc _boardCenter 	; boardCenter.x
	sta COLCRS 

	; row = row * 2 + boardCenter.y - layerOffset[level].y
	jsr popa 
	sta OLDROW
	asl a 
	adc _boardCenter+1 	; boardCenter.y
	sta ROWCRS

	; offset = layerOffset[level]
	jsr popa 			; level
	asl a 
	tax 
	lda COLCRS
	sec
	sbc layerOffset,X 	; offset.x
	sta COLCRS 

	lda ROWCRS
	sec
	sbc layerOffset+1,X	; offset.y
	sta ROWCRS 

	; Special case for layer 0 far left and far right tiles
	cpx #0
	bne skip_layer0
		lda OLDCOL
		cmp #0 
		bne skip_left_endcap
			inc ROWCRS
			jmp skip_layer0
		skip_left_endcap:
		cmp #13
		bne skip_right_endcap
			lda OLDROW
			cmp #3
			bne skip_second_to_last
				inc ROWCRS
				jmp skip_right_endcap
			skip_second_to_last:
			cmp #4
			bne skip_last
				dec ROWCRS
				inc COLCRS
				inc COLCRS
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
	.import popa
	.import _setSavadrToCursor

    ;sta ROWCRS         ; y
    ;jsr popa
    ;sec 
    ;sbc #1
    ;sta COLCRS         ; x
    ;jsr popa 

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
