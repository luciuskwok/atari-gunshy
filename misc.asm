; misc.asm 


; void zeroOutMemory(uint8_t *ptr, uint16_t length);
.export _zeroOutMemory
.proc _zeroOutMemory
	.importzp sreg, ptr1 
	.import popax

	length = ptr1 
	sta length			; ptr1 = parmeter 'length'
	stx length+1

	ptr = sreg
	jsr popax 
	sta ptr
	stx ptr+1

	jsr addSregToPtr1	; set length to point at end of area to zero out

	ldy #0
	loop:
		lda #0
		sta (ptr),Y
		inc ptr 
		bne while
		inc ptr+1
	while:
		lda ptr 
		cmp length
		bne loop
		lda ptr+1
		cmp length+1
		bne loop
	rts 
.endproc 

.export zeroOutAXY
.proc zeroOutAXY
	; On entry: pointer in AX, length in Y.
	.importzp ptr1 
	sta ptr1 
	stx ptr1+1
	lda #0
	loop:
		dey 
		sta (ptr1),Y
		bne loop
	rts 
.endproc

.export mulax40
.proc mulax40 
	; 40 = %0010 1000
	.importzp sreg

	sta sreg  		; A=LSB
	stx sreg+1 		; X=MSB
	asl a 
	rol sreg+1
	asl a
	rol sreg+1
	clc 
	adc sreg 
	sta sreg
	txa  			; flip LSB/MSB, so A=MSB, X=LSB
	adc sreg+1 
	asl sreg
	rol a
	asl sreg 
	rol a
	asl sreg
	rol a 
	tax 
	lda sreg 
	rts 
.endproc 

.export addSregToPtr1
.proc addSregToPtr1
	.importzp sreg, ptr1 
	clc 
	lda ptr1 
	adc sreg 
	sta ptr1 
	lda ptr1+1
	adc sreg+1
	sta ptr1+1
	rts 
.endproc 
