$NOMOD51
NAME proc_b
; module for process a

#include <Reg517a.inc>
#include "variables.inc"

PUBLIC proc_b
EXTRN CODE (serial_out)
	
proc_b_code SEGMENT CODE
	RSEG proc_b_code
	
proc_b:
	
	MOV R0, SECONDS_TIMER	; save value of current SECONDS_TIMER
	
	check_timer:
		
		SETB WDT
		SETB SWDT
		
		MOV A, R0 ; get saved value of SECONDS_TIMER
		
		CJNE A, SECONDS_TIMER, write	; check if SECONDS_TIMER has changed
		JMP check_timer
				
		write:	
			
			MOV R0, SECONDS_TIMER ; save new value of SECONDS_TIMER
			
			MOV B, #'+'
			LCALL serial_out	; write to serial output
				
			JMP check_timer

END
			