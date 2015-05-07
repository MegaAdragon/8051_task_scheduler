;-----------------------------------------------
;
; Process a module
;
;-----------------------------------------------

$NOMOD51
NAME proc_a


#include <Reg517a.inc>
#include "variables.inc"

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
	
	MOV PROC_ALIVE, #0x00
	
	; loop until process is killed
	loop:
		SETB WDT
		SETB SWDT
		
		JMP loop

END