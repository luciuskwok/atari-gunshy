; graphics.asm

.include "atari_memmap.inc"
.include "global.inc"


; Global Variables
.bss
	.export _spritePage
	_spritePage: .res 1

.data 
	prevSelectedTileSpriteY: .byte 0

; Constant data
.rodata 

	colorTable:
		.byte $58	; P0: mouse pointer sprite
		.byte $0E	; P1 sprite
		.byte $0E	; P2 sprite
		.byte $00	; P3: apex tile left border sprite
		.byte $0E	; COLOR0: white
		.byte $36	; COLOR1: red
		.byte $B4	; COLOR2: green
		.byte $92	; COLOR3: blue
		.byte $00	; COLOR4: background, black
		.byte $0E	; COLOR5: DLI text luminance, white
		.byte $B2	; COLOR6: DLI text bkgnd, dark green
		.byte $00	; COLOR7: unused

	selectedTileSprite:
		.byte $FC, $84, $84, $84, $84, $84, $84, $84, $84, $FC
		selectedTileSprite_length = 10

; Display List instructions
	DL_JVB    = $41
	DL_BLK1   = $00
	DL_BLK2   = $10
	DL_BLK3   = $20
	DL_BLK4   = $30
	DL_BLK5   = $40
	DL_BLK6   = $50
	DL_BLK7   = $60
	DL_BLK8   = $70
	DL_HSCROL = $10
	DL_VSCROL = $20
	DL_LMS    = $40
	DL_DLI    = $80
	DL_TEXT   = $02
	DL_TILE   = $04
.code

; void setSelectedTile(uint8_t x, uint8_t y);
.export _setSelectedTile 
.proc _setSelectedTile
	.importzp sreg 
	.import popa

	asl a  			; Y = row * 4 + PMTopMargin
	asl a 
	clc 
	adc #PMTopMargin
	cmp prevSelectedTileSpriteY
	beq set_X
		pha 

		lda #1  		; Get player P0 sprite memory
		jsr _getSpritePtr
		sta sreg 
		stx sreg+1

		; Erase the old sprite
		ldy prevSelectedTileSpriteY
		ldx #selectedTileSprite_length
		lda #0
		loop_erase:
			sta (sreg),Y 
			iny 
			dex 
			bne loop_erase

		; Draw the sprite at the new Y position
		pla 
		sta prevSelectedTileSpriteY 	; update previous value
		tay
		pha 
		ldx #0
		loop_draw:
			lda selectedTileSprite,x
			sta (sreg),Y 
			iny 
			inx
			cpx #selectedTileSprite_length 
			bne loop_draw

	set_X:
		jsr popa  		; X = row * 4 + PMLeftMargin
		asl a 
		asl a 
		clc 
		adc #PMLeftMargin
		sta HPOSP1

	rts
.endproc

; uint8_t* getSpritePtr(uint8_t sprite);
.export _getSpritePtr
.proc _getSpritePtr
	; on entry: A = 0 for missiles, 1-4 for players P0-P3
	clc 
	adc #3 
	lsr a 
	tax  		; Store MSB in X
	lda #0
	ror a 		; This sets A to $80 if carry was set
	tay 		; Store LSB in Y temporarily
	txa 
	clc 		; Add MSB to spritePage
	adc _spritePage 
	tax 		; MSB in X for return result
	tya 		; LSB in A for return result
	rts 
.endproc 

; void printStringAtXY(const char *s, uint8_t x, uint8_t y);
.export _printStringAtXY
.proc _printStringAtXY
	.importzp ptr1
	.import popptr1, popa

	sta ROWCRS   		; parameter 'y'

	jsr popa  			; parameter 'x'
	sta COLCRS 
	sta LMARGN

	lda #0
	sta BITMSK 			; set BITMASK to 0 
	
	jsr popptr1 		; parameter 's'
	lda ptr1
	ldx ptr1+1

	jsr _printString
	rts
.endproc

; void printString(const char *s);
.export _printString
.proc _printString 
	.importzp ptr2

	string = ptr2 
		sta string 
		stx string+1

	jsr _setSavadrToCursor ; uses sreg

	ldy #0
	loop:
		lda(string),Y
		beq inc_colcrs		; if string[Y] == 0: break
		jsr _toAtascii
		ora BITMSK
		sta(SAVADR),Y		; screen[Y] = string[Y]
		iny
		bne loop
	inc_colcrs:
		tya 
		clc 
		adc COLCRS
		sta COLCRS
	return:
		rts
.endproc 

; void moveToNextLine(void);
.export _moveToNextLine 
.proc _moveToNextLine 
	lda LMARGN 
	sta COLCRS 
	inc ROWCRS
	rts 	
.endproc 

; void setSavadrToCursor(void);
.export _setSavadrToCursor
.proc _setSavadrToCursor 
	; Stores cursor address in SAVADR.
	.import mulax40 ; uses sreg

	lda ROWCRS 
	ldx #0 
	jsr mulax40			; returns result in AX

	clc 				; SAVADR = AX + TXTMSC
	adc SAVMSC 
	sta SAVADR
	txa 
	adc SAVMSC+1
	sta SAVADR+1

	lda COLCRS			; SAVADR += COLCRS
	clc 		
	adc SAVADR 
	sta SAVADR
	bcc @skip_msb 
		inc SAVADR+1
	@skip_msb:

	rts 
.endproc

; uint8_t toAtascii(uint8_t c);
.export _toAtascii
.proc _toAtascii
	cmp #$20			; if A < $20: 
	bcs mid_char
	adc #$40			; A += $40
	rts
	mid_char:
		cmp #$60		; else if A < $60
		bcs return
		sec				; A -= $20
		sbc #$20
	return:
		rts
.endproc

; void delayTicks(uint8_t ticks);
.export _delayTicks
.proc _delayTicks
	clc
	adc RTCLOK_LSB
	loop:
		cmp RTCLOK_LSB
		bne loop 
	rts
.endproc

; void initGraphics(void);
.export _initGraphics
.proc _initGraphics

	; Constants
	anticOptions = $2E 	; normal playfield, enable players & missiles, enable DMA
	enableDLI    = $C0  ; enable VBI + DLI

	lda #0 			; erase text cursor
	ldy #2 
	sta (SAVMSC),Y
	
	lda #0			; Turn off screen during init
	sta SDMCTL

	lda #1			; Wait for VSYNC
	jsr _delayTicks 

	ldy #11			; load color table
	loop_color:
		lda colorTable,Y 
		sta PCOLR0,Y
		dey 
		bpl loop_color

	; Reserved memory layout:
	; 1 kB (4 pages): sprite area
	; 1 kB (4 pages): screen graphics area (already set up by runtime)
	lda RAMTOP 
	sec 
	sbc #8 			; 8 pages = 2 kB below RAMTOP
	sta _spritePage

	jsr initDisplayList
	jsr initSprite

	; Restore screen
	lda #$20 		; switch to custom font
	sta CHBAS 
	lda #enableDLI 	; enable DLI+VBI
	sta NMIEN
	lda #anticOptions ; turn screen back on
	sta SDMCTL

	rts 
.endproc 

.proc initDisplayList
	.importzp ptr1 
	.import _DLI

	; Modify existing display list
	lda SDLSTL 
	sta ptr1 
	lda SDLSTL+1
	sta ptr1+1

	ldy #3
	lda #DL_TILE|DL_LMS 
	sta (ptr1),Y 		; 1 row of tiles

	ldy #6
	lda #DL_TILE
	loop_dl_tiles:
		sta (ptr1),Y
		iny 
		cpy #(19+6) 	; 19 more row of tiles
		bne loop_dl_tiles 	

	lda #DL_TILE|DL_DLI ; 1 more row of tiles, this with DLI
	sta (ptr1),Y		; = 21 total rows of tiles
	iny 

	lda #DL_TEXT
	sta (ptr1),Y		; text
	iny 

	sta (ptr1),Y		; text
	iny 

	lda #DL_TEXT|DL_DLI
	sta (ptr1),Y		; text | last-line DLI
	iny 

	; Enable DLI
	lda #<_DLI
	sta VDSLST
	lda #>_DLI
	sta VDSLST+1

	rts
.endproc

.proc initSprite
	.importzp ptr1
	.import pushax 
	.import zeroOutPtr1
	.import _zeroOutMemory

	spriteArea = SAVADR
		lda _spritePage
		sta spriteArea+1
		lda #0
		sta spriteArea 

	; Clear 1024 bytes in sprite area
		lda #0 			; ptr = spriteArea
		ldx _spritePage
		jsr pushax
		lda #0			; length = 4*256 = 1 kB
		ldx #4
		jsr _zeroOutMemory 	

	; Clear GTIA registers 
		lda #<HPOSP0
		sta ptr1 
		lda #>HPOSP0
		sta ptr1+1
		ldy #12
		jsr zeroOutPtr1

	; Set up ANTIC
		lda _spritePage 
		sta PMBASE
		lda #$11	; layer players above playfield, missiles use COLOR3
		sta GPRIOR
		lda #3		; enable both missiles & players 
		sta GRACTL

	rts
.endproc 

