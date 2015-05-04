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
	
	MOV R0, SECONDS_TIMER
	
	check_time_slice:
		
		SETB WDT
		SETB SWDT
		
		MOV A, R0
		
		CJNE A, SECONDS_TIMER, inc_timer
		JMP check_time_slice
				
		inc_timer:	
			
			MOV R0, SECONDS_TIMER
			;save new time slice status
			; do stuff
			MOV B, #'+'
			LCALL serial_out
				
			JMP check_time_slice

END
			