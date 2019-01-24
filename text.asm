; text.asm

.include "atari_memmap.inc"
.include "global.inc"


; void printStringAtXY(const char *s, uint8_t x, uint8_t y);
.export _printStringAtXY
.proc _printStringAtXY
	.importzp ptr1
	.import popax, popa

	sta ROWCRS   		; parameter 'y'

	jsr popa  			; parameter 'x'
	sta COLCRS 
	sta LMARGN

	lda #0
	sta BITMSK 			; set BITMASK to 0 
	
	jsr popax 		; parameter 's'

	jsr _printString
	rts
.endproc

; void printString(const char *s);
.export _printString
.proc _printString 
	.importzp ptr2
	.import _setSavadrToCursor

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

; char toAtascii(char c);
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

; uint8_t uint16String(char *string, uint16_t value);
.export _uint16String
.proc _uint16String
	; returns length of string
	.importzp sreg, ptr1, ptr2, ptr4, tmp1
	.import udiv16 ; uses sreg, ptr1, ptr4, AXY
	.import popax 

	value = ptr1
		sta value
		stx value+1

	divisor = ptr4
	remainder = sreg

	string = ptr2
		jsr popax 
		sta string 
		stx string+1

	index = tmp1
		lda #0
		sta index

	loop_push:
		lda #10 		; reset divisor to 10 because udiv16 will modify it
		sta divisor
		lda #0
		sta divisor+1

		jsr udiv16 		; divide value / divisor: ptr1=result, sreg=remainder

		lda remainder 	; get remainder
		clc 
		adc #$30 		; add ascii '0' char to remainder to get digits

		pha 			; push digit onto stack
		inc index 

		lda value 		; if value != 0: next loop
		bne loop_push
		lda value+1
		bne loop_push 

	ldy #0 
	loop_pull:
		pla  			; pull digits
		sta (string),Y	; and add them in the correct order
		iny 
		cpy index 
		bne loop_pull

	lda #0 				; terminate string with NULL
	sta (string),Y

	tya 				; return length
	ldx #0
	rts
.endproc 


; void printHex(uint16_t value);
.export _printHex 
.proc _printHex
	.importzp ptr1 
	.import _setSavadrToCursor

	sta ptr1+1 ; store in big-endian format
	stx ptr1

	jsr _setSavadrToCursor ; uses sreg

	ldy #0 
	loop:
		lda #0  	; A = top 4 bits of ptr1
		asl ptr1+1
		rol ptr1 
		rol a 
		asl ptr1+1
		rol ptr1 
		rol a 
		asl ptr1+1
		rol ptr1 
		rol a 
		asl ptr1+1
		rol ptr1 
		rol a 

		cmp #10
		bcs hex_char
		dec_char:
			clc
			adc #'0'-$20 ; Convert constant to ATASCII
			sta (SAVADR),Y 
			jmp next_loop
		hex_char:
			clc 
			adc #'A'-$20-10 ; Convert constant to ATASCII
			sta (SAVADR),Y 
		next_loop:
			iny 
			cpy #4
			bne loop 
	rts
.endproc 
