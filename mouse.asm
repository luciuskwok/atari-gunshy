; mouse.asm 

.include "atari_memmap.inc"
.include "global.inc"

; Constants
.rodata 
	mousePointerData:
		.byte $80, $C0, $E0, $F0, $F8, $FC, $FE, $F0, $98, $18, $0C
		mousePointer_length = 11
	STMouseLookupTable:
		.byte $00, $FF, $01, $00 ; 0000, 0001, 0010, 0011
		.byte $01, $00, $00, $FF ; 0100, 0101, 0110, 0111
		.byte $FF, $00, $00, $01 ; 1000, 1001, 1010, 1011
		.byte $00, $01, $FF, $00 ; 1100, 1101, 1110, 1111

; Global Variables
.data

	.export _mouseLocation ; point_t mouseLocation; 
	_mouseLocation:
		_mouseLocX: .byte PMLeftMargin+12 ; start pointer in top-left
		_mouseLocY: .byte PMTopMargin+8

	prevMouseLocX: .byte 0
	prevMouseLocY: .byte 0

	mouseMinX: .byte PMLeftMargin
	mouseMaxX: .byte PMLeftMargin+PMWidth-1
	mouseMinY: .byte PMTopMargin
	mouseMaxY: .byte PMTopMargin+PMHeight-1



	.export _pointerHasMoved
	_pointerHasMoved: .byte 0

	mouseQuadX: .byte 0
	mouseQuadY: .byte 0

.segment "EXTZP": zeropage
	mouseSprite: .word 0
	mouseTemp: .byte 0

.code 


.export _mouseVBI
.proc _mouseVBI
	jsr handleJoystick
	jsr redrawPointer 
	rts 
.endproc

.proc redrawPointer
	; Redraw the mouse pointer. This is called from the deferred VBI handler.

	; Set X position
	lda _mouseLocX 
	cmp prevMouseLocX
	beq skip_x
		sta HPOSP0
		sta prevMouseLocX
		lda #1 
		sta _pointerHasMoved
	skip_x:

	; Set Y position
	lda _mouseLocY
	cmp prevMouseLocY 
	beq skip_y
		pha ; Save mouseLocY on stack 

		; Erase old pointer
		ldx #mousePointer_length
		ldy prevMouseLocY
		lda #0
		loop_erase:
			sta (mouseSprite),Y 
			iny 
			dex 
			bne loop_erase

		; Draw pointer in new location
		ldx #0
		pla 
		tay
		pha 
		loop_draw:
			lda mousePointerData,X
			sta (mouseSprite),Y 
			iny 
			inx 
			cpx #mousePointer_length 
			bne loop_draw
	
		pla 
		sta prevMouseLocY
		lda #1 
		sta _pointerHasMoved
	skip_y:
	rts 
.endproc 

.proc handleJoystick
	lda PORTA 		; use joystick plugged into STICK0 (first port)
	tax 

	and #$01 
	bne @skip_up
		lda #$FF
		jsr movePointerY 
	@skip_up: 

	txa 
	and #$02 
	bne @skip_down
		lda #$01
		jsr movePointerY 
	@skip_down: 

	txa 
	and #$04 
	bne @skip_left
		lda #$FF
		jsr movePointerX 
	@skip_left: 

	txa 
	and #$08 
	bne @skip_right
		lda #$01
		jsr movePointerX 
	@skip_right: 

	rts 
.endproc 

.proc movePointerX 
	clc 
	adc _mouseLocX 
	cmp mouseMinX 		; if x < mouseMinX: x = mouseMinX
	bcs not_less
		lda mouseMinX
	not_less:
	cmp mouseMaxX 		; if x >= mouseMaxX: x = mouseMaxX
	bcc not_more
		lda mouseMaxX
	not_more:
	sta _mouseLocX
	rts
.endproc 

.proc movePointerY 
	clc 
	adc _mouseLocY 
	cmp mouseMinY 		; if y < mouseMinY: y = mouseMinY
	bcs not_less
		lda mouseMinY
	not_less:
	cmp mouseMaxY 		; if y >= mouseMaxY: y = mouseMaxY
	bcc not_more
		lda mouseMaxY
	not_more:
	sta _mouseLocY
	rts
.endproc 

.proc _timer1Handler
	; Timer 1 Interrupt Service Routine
	; OS IRQ handler already pushed A onto stack
	txa
	pha 
	tya 
	pha 

	lda PORTA 		; use mouse plugged into STICK1 (second port)
	lsr a
	lsr a 
	lsr a
	lsr a 
	tay 

	and #$03 		; Work on X quadrature outputs
	sta mouseTemp  
	lda mouseQuadX	; Move the lower 2 bits to the upper 2 bits.
	asl a 			; This represents the previous state of the quads.
	asl a 
	ora mouseTemp	; Add the current state of the quads.
	and #$0F 
	sta mouseQuadX 
	tax 			; Use the 4-bit value as an index into a lookup table.
	lda STMouseLookupTable,X 
	beq skip_moveX
		jsr movePointerX 
	skip_moveX:

	tya 
	lsr a 
	lsr a 
	and #$03 
	sta mouseTemp 
	lda mouseQuadY	; Move the lower 2 bits to the upper 2 bits.
	asl a 			; This represents the previous state of the quads.
	asl a 
	ora mouseTemp	; Add the current state of the quads.
	and #$0F 
	sta mouseQuadY 
	tax 			; Use the 4-bit value as an index into a lookup table.
	lda STMouseLookupTable,X 
	beq skip_moveY
		jsr movePointerY 
	skip_moveY:

	return:
		pla 
		tay
		pla 
		tax 
		pla 
		rti
.endproc

.proc _startTimer1 
	lda #64 	; Set timer frequency
	sta AUDF1	; Hz = 63921 / (2 * (AUDF1 + 1))
	 			; AUDF=64: 491.7 Hz

	lda #$10 	; Set audio channel 1 to use volume-only mode.
	sta AUDC1 	; This makes it effectively silent.

	lda #$C1	; Enable VTIMR1, keyboard, and break key ISRs.
	sta POKMSK	; Shadow of IRQEN
	sta IRQEN
	sta STIMER	; Restart timers
	rts 
.endproc 

.proc _stopTimer1 
	lda #$C0
	sta POKMSK	; Shadow of IRQEN
	sta IRQEN
	rts 
.endproc 

; void initMouse(void);
.export _initMouse
.proc _initMouse 
	.import _spritePage

	lda #0 				; set mouseSprite to point at player0 area
	sta mouseSprite 	; which is 512 bytes into sprite area
	lda _spritePage
	clc 
	adc #2
	sta mouseSprite+1

	lda #<_timer1Handler ; Install timer 1 handler
	sta VTIMR1 
	lda #>_timer1Handler
	sta VTIMR1+1

	lda #0 		; Set audio control to defaults (64 kHz base clock)
	sta AUDCTL
	lda #3
	sta SKCTL

	jsr _startTimer1 ; Start timer handler for mouse

	rts 
.endproc
