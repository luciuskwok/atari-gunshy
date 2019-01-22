; interrupts.asm 

.include "atari_memmap.inc"

; Global Variables
.data 
	_enableColorCycling: .byte 1

.code 

.export _initVBI
.proc _initVBI
	.import initMouse

	jsr initMouse

	ldy #<immediateUserVBI
	ldx #>immediateUserVBI
	lda #6			; 6=Immediate, 7=Deferred.
	jsr $E45C		; SETVBV: Y=LSB, X=MSB

	ldy #<deferredUserVBI
	ldx #>deferredUserVBI
	lda #7			; 6=Immediate, 7=Deferred.
	jsr $E45C		; SETVBV: Y=LSB, X=MSB

	rts
.endproc 


.proc immediateUserVBI
	.import mouseImmediateVBI
	jsr mouseImmediateVBI
	jsr cyclePointerColor
	jmp SYSVBV			; jump to the OS immediate VBI routine
.endproc

.proc cyclePointerColor
	lda _enableColorCycling
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

.proc deferredUserVBI
	.import mouseDeferredVBI

	jsr mouseDeferredVBI
	
	return:
		jmp XITVBV
.endproc


.export _DLI
.proc _DLI
	vcountTopMargin = 15

	pha					

	lda VCOUNT 			; use debugger to get actual VCOUNT values
	cmp #vcountTopMargin+96
	bcs last_line 

	text_box:
		lda COLOR6
			sta WSYNC		; wait for horizontal sync
			sta COLPF2		; text box background
		lda COLOR5
			sta COLPF1		; text color
		lda #$E0
			sta CHBASE		; ROM font
		jmp return

	last_line:
		lda COLOR2			; restore graphics colors
			sta WSYNC		; wait for horizontal sync
			sta COLPF2		
		lda COLOR1
			sta COLPF1		
		lda CHBAS
			sta CHBASE		; custom font

	return:
		pla
		rti
.endproc 
