$NOMOD51
NAME proc_console
; module for console process

#include <Reg517a.inc>
#include "variables.inc"

PUBLIC proc_console
EXTRN CODE (serial_in)
EXTRN CODE (new_proc)
EXTRN CODE (proc_a)
EXTRN CODE (proc_b)
	
proc_console_code SEGMENT CODE
	RSEG proc_console_code
		
proc_console:

	loop:
	
		SETB WDT
		SETB SWDT
		
		LCALL serial_in
		
		MOV A,B
		
		JNB F0, loop
			
			check_a:
				CJNE A, #'a', check_b
				
				CLR ET0
				MOV DPTR, #proc_a
				MOV PRC_ADR_L, DPL
				MOV PRC_ADR_H, DPH	
				MOV PROC_TYPE_ID, #ID_CON
				MOV PRIO, #0x05
				MOV PROC_ALIVE, #0x01
				LCALL new_proc	
			
				
				SETB ET0
				JMP loop;
			
			check_b:
			
				NOP
				NOP
				
				JMP loop
				

				
			
			
			
			
			

	
END		
