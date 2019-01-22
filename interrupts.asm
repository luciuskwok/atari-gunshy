; interrupts.asm 

.include "atari_memmap.inc"

; Global Variables
.bss


.code 

.export _initVBI
.proc _initVBI
	.import _initMouse

	jsr _initMouse

	ldy #<_immediateUserVBI
	ldx #>_immediateUserVBI
	lda #6			; 6=Immediate, 7=Deferred.
	jsr $E45C		; SETVBV: Y=LSB, X=MSB

	ldy #<_deferredUserVBI
	ldx #>_deferredUserVBI
	lda #7			; 6=Immediate, 7=Deferred.
	jsr $E45C		; SETVBV: Y=LSB, X=MSB

	rts
.endproc 


.proc _immediateUserVBI
	jmp SYSVBV			; jump to the OS immediate VBI routine
.endproc


.proc _deferredUserVBI
	.import _mouseVBI

	jsr _mouseVBI
	
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
