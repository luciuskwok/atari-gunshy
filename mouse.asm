; mouse.asm 

.include "atari_memmap.asm"


; Global Variables
.bss

.export _mouseLocation ; point_t mouseLocation; 
	_mouseLocation:
		_mouseLocX: .res 1
		_mouseLocY: .res 1

	_prevMouseLocation:
		_prevMouseLocX: .res 1 
		_prevMouseLocY: .res 1


.code 

.proc _T1_ISR
	; Timer 1 Interrupt Service Routine
	txa
	pha 

	return:
		pla 
		tax 
		pla 
		rti
.endproc


.export _mouseVBI
.proc _mouseVBI
	; Update the mouse pointer in the deferred VBI

	


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
	lda #80		; Center mouse pointer on screen
	sta _mouseLocX
	lda #48
	sta _mouseLocY
	lda #0
	sta _prevMouseLocX
	sta _prevMouseLocY

	lda #<_T1_ISR ; Install timer 1 handler
	sta VTIMR1 
	lda #>_T1_ISR
	sta VTIMR1+1

	lda #0 		; Set audio control to defaults (64 kHz base clock)
	sta AUDCTL
	lda #3
	sta SKCTL

	jsr _startTimer1 ; Start timer handler for mouse

	rts 
.endproc
