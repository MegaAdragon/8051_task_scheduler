$NOMOD51
NAME proc_a
; module for process a

#include <Reg517a.inc>

PUBLIC proc_a
EXTRN CODE (serial_out)
	
proc_a_code SEGMENT CODE
	RSEG proc_a_code
	
proc_a:
	
	; output 'a'
	MOV B, #'a'
	LCALL serial_out
	
	; output 'b'
	MOV B, #'b'
	LCALL serial_out
	
	; output 'c'
	MOV B, #'c'
	LCALL serial_out
	
	; output 'd'
	MOV B, #'d'
	LCALL serial_out
	
	; output 'e'
	MOV B, #'e'
	LCALL serial_out
	
	loop:
		NOP
		JMP loop

END