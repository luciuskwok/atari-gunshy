; mouse.asm 

.include "atari_memmap.asm"


; Constants
.rodata 
	PMLeftMargin = 48
	PMWidth = 160
	PMTopMargin = 16
	PMHeight = 96
	MousePointerLength = 11
	mousePointerData:
		.byte $80, $C0, $E0, $F0, $F8, $FC, $FE, $F0, $98, $18, $0C
	STMouseLookupTable:
		.byte $00, $FF, $01, $00 ; 0000, 0001, 0010, 0011
		.byte $01, $00, $00, $FF ; 0100, 0101, 0110, 0111
		.byte $FF, $00, $00, $01 ; 1000, 1001, 1010, 1011
		.byte $00, $01, $FF, $00 ; 1100, 1101, 1110, 1111

; Global Variables
.data

.export _mouseLocation ; point_t mouseLocation; 
	_mouseLocation:
		_mouseLocX: .byte 0
		_mouseLocY: .byte 0

	_prevMouseLocation:
		_prevMouseLocX: .byte 0
		_prevMouseLocY: .byte 0

	_mouseMinX: .byte PMLeftMargin
	_mouseMaxX: .byte PMLeftMargin+PMWidth-1
	_mouseMinY: .byte PMTopMargin
	_mouseMaxY: .byte PMTopMargin+PMHeight-1

	_pointerColorCycle: .byte 1

	mouseQuadX: .byte 0
	mouseQuadY: .byte 0

.segment "EXTZP": zeropage
	mouseSprite: .word 0
	mouseTemp: .byte 0

.code 


.export _mouseVBI
.proc _mouseVBI
	jsr cyclePointerColor
	jsr handleJoystick
	jsr redrawPointer 
	rts 
.endproc

.proc cyclePointerColor

	lda _pointerColorCycle
	beq return 

	lda RTCLOK_LSB		; update every 16 frames
	tax 
	and #$0F
	bne return 
		lda PCOLR0 		; mask out luminance
		and #$F0
		sta PCOLR0 

		txa 
		bpl @skip_eor
			eor #$FF 	; negate value
		@skip_eor:
		lsr a
		lsr a
		lsr a
		ora PCOLR0 
		sta PCOLR0		; store new color value
	return:
	rts 
.endproc 

.proc redrawPointer
	; Redraw the mouse pointer. This is called from the deferred VBI handler.

	; Set X position
	lda _mouseLocX 
	sta HPOSP0
	sta _prevMouseLocX

	; Set Y position
	lda _mouseLocY
	cmp _prevMouseLocY 
	beq skip_y
		; Erase old pointer
		ldx #MousePointerLength
		ldy _prevMouseLocY
		lda #0
		loop_erase:
			sta (mouseSprite),Y 
			iny 
			dex 
			bne loop_erase

		; Draw pointer in new location
		ldx #0
		ldy _mouseLocY
		loop_draw:
			lda mousePointerData,X
			sta (mouseSprite),Y 
			iny 
			inx 
			cpx #MousePointerLength 
			bne loop_draw
	
		lda _mouseLocY 
		sta _prevMouseLocY
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
	cmp _mouseMinX 		; if x < mouseMinX: x = mouseMinX
	bcs not_less
		lda _mouseMinX
	not_less:
	cmp _mouseMaxX 		; if x >= mouseMaxX: x = mouseMaxX
	bcc not_more
		lda _mouseMaxX
	not_more:
	sta _mouseLocX
	rts
.endproc 

.proc movePointerY 
	clc 
	adc _mouseLocY 
	cmp _mouseMinY 		; if y < mouseMinY: y = mouseMinY
	bcs not_less
		lda _mouseMinY
	not_less:
	cmp _mouseMaxY 		; if y >= mouseMaxY: y = mouseMaxY
	bcc not_more
		lda _mouseMaxY
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

	lda #PMLeftMargin+80 ; Center mouse pointer on screen
	sta _mouseLocX
	lda #PMTopMargin+48
	sta _mouseLocY
	lda #0
	sta _prevMouseLocX
	sta _prevMouseLocY

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
