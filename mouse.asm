; mouse.asm 

.include "atari_memmap.asm"


; Global Variables
.data

.export _mouseLocation ; point_t mouseLocation; 
	_mouseLocation:
		_mouseLocX: .byte 0
		_mouseLocY: .byte 0

	_prevMouseLocation:
		_prevMouseLocX: .byte 0
		_prevMouseLocY: .byte 0

	_pointerColorCycle: .byte 0

.segment "EXTZP": zeropage
	mouseSprite: .word 0

; Constants
.rodata 
	PMLeftMargin = 14
	PMTopMargin = 15
	MousePointerLength = 11
	mousePointerData:
		.byte $80, $C0, $E0, $F0, $F8, $FC, $FC, $F0, $98, $18, $0C

.code 

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
	tax 




	return:
		pla 
		tay
		pla 
		tax 
		pla 
		rti
.endproc


.export _mouseVBI
.proc _mouseVBI

	jsr redrawPointer 
	jsr cyclePointerColor

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
	sta _prevMouseLocX
	clc 
	adc #PMLeftMargin
	sta HPOSP0

	; Set Y position
	lda _mouseLocY
	cmp _prevMouseLocY 
	beq skip_y
		sta _prevMouseLocY

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
	skip_y:
	rts 
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

	lda #80		; Center mouse pointer on screen
	sta _mouseLocX
	lda #48
	sta _mouseLocY
	lda #0
	sta _prevMouseLocX
	sta _prevMouseLocY

	lda #1 				; Enable mouse pointer color cycling
	sta _pointerColorCycle 

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
