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
	
	;counter for timer
	MOV R0, #0x00
	; save current time slice status
	MOV R1, TIME_SLICE_STAT
	
	check_time_slice:
		
		SETB WDT
		SETB SWDT
		
		MOV A,R1
		
		CJNE A, TIME_SLICE_STAT, inc_timer
		JMP check_time_slice
		
		inc_timer:
			
			;save new time slice status
			MOV R1, TIME_SLICE_STAT
			
			;increment timer
			INC R0
			MOV A, R0
			
			CJNE A, #40, check_time_slice
				; reset counter
				MOV R0, #0x00
				
				; do stuff
				MOV B, #'+'
				LCALL serial_out
				
			JMP check_time_slice

END
			