; graphics.asm

.include "atari_memmap.inc"
.include "global.inc"


; Global Variables
.bss
	.export _spritePage
	_spritePage: .res 1
	.export _fontPage
	_fontPage: .res 1

.data 
	prevSelectedTileSpriteY: .byte 0

; Constant data
.rodata 

	colorTable:
		.byte $58	; P0: mouse pointer
		.byte $6A	; P1: selected tile effect 
		.byte $0E	; P2 sprite
		.byte $02	; P3: apex tile left border
		.byte $0E	; COLOR0: white
		.byte $36	; COLOR1: red
		.byte $B4	; COLOR2: green
		.byte $94	; COLOR3: blue
		.byte $00	; COLOR4: background, black
		.byte $0E	; COLOR5: DLI text luminance, white
		.byte $B2	; COLOR6: DLI text bkgnd, dark green
		.byte $00	; COLOR7: unused

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

; void setSelectionLocation(uint8_t x, uint8_t y);
.export _setSelectionLocation
.proc _setSelectionLocation
	.import popa
	.import selectionLocX, selectionLocY, selectionHasMoved

	asl a  			; Y = row * 4 + PMTopMargin
	asl a 
	clc 
	adc #PMTopMargin
	sta selectionLocY

	jsr popa  		; X = row * 4 + PMLeftMargin
	asl a 
	asl a 
	clc 
	adc #PMLeftMargin-1
	sta selectionLocX

	lda #1 
	sta selectionHasMoved

	rts
.endproc

; void hideSelection(void);
.export _hideSelection
.proc _hideSelection 
	.import selectionLocX
	lda #0
	sta selectionLocX
	sta HPOSP1
	sta HPOSM1
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
	.import pushax 
	.import _zeroOutMemory
	.import initVBI

	; Constants
	anticOptions = $2E 	; normal playfield, enable players & missiles, enable DMA
	enableDLI    = $C0  ; enable VBI + DLI
	
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
	; Total reserved memory below RAMTOP is 9 kB. 
	; 1 kB (4 pages): screen area (already set up by runtime)
	; 7 kB (28 pages): font area
	; 1 kB (4 pages): sprite area
	lda RAMTOP 

	sec 
	sbc #32 
	sta _fontPage 	; 32 pages = 8 kB below RAMTOP

	sec 
	sbc #4 			; 4 pages = 1 kB below fontPage
	sta _spritePage

	; Clear reserved memory, except for screen area
	tax 
	lda #0
	jsr pushax
	lda #0			; length = 8*4*256 = 8 kB
	ldx #8*4
	jsr _zeroOutMemory 	

	jsr initDisplayList
	jsr initSprite
	jsr initVBI

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

	.rodata 
	displayList:
		.byte $70, $70, $70 	; 3 * 8 blank lines
		.byte DL_TILE|DL_LMS
		.byte 0, 0
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TILE
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TILE
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TILE
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TILE
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TILE
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TILE
		.byte DL_TILE
		.byte DL_TILE|DL_DLI
		.byte DL_TEXT 			; begin text box
		.byte DL_TEXT
		.byte DL_TEXT|DL_DLI 	; last-line DLI
		.byte DL_JVB
	.code

	; Write custom display list
	lda SDLSTL 
	sta ptr1 
	lda SDLSTL+1
	sta ptr1+1

	ldy #0
	loop:
		lda displayList,Y 
		sta (ptr1),Y 
		iny 

		cmp #DL_JVB		; if JVB: append SDLSTL value and end loop
		bne skip_jvb
			lda ptr1
			sta (ptr1),Y 
			iny 
			lda ptr1+1
			sta (ptr1),Y 
			jmp end_loop
		skip_jvb:

		tax 
		and #$0F 
		beq loop 		; if blank lines: continue

		txa 
		and #DL_LMS 	; if LMS: append SAVMSC and continue
		beq loop 
			lda SAVMSC 
			sta (ptr1),Y 
			iny 
			lda SAVMSC+1 
			sta (ptr1),Y 
			iny 
			jmp loop 
	end_loop:

	; Enable DLI
	lda #<_DLI
	sta VDSLST
	lda #>_DLI
	sta VDSLST+1

	rts
.endproc

.proc initSprite
	.import zeroOutAXY

	; Clear GTIA registers 
		lda #<HPOSP0
		ldx #>HPOSP0
		ldy #12
		jsr zeroOutAXY

	; Set up ANTIC
		lda _spritePage 
		sta PMBASE
		lda #$01	; layers sprites above everything
		sta GPRIOR
		lda #3		; enable both missiles & players 
		sta GRACTL
	rts
.endproc 
