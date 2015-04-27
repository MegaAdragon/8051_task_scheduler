$NOMOD51
NAME proc_console
; module for console process

#include <Reg517a.inc>

PUBLIC proc_console
EXTRN CODE (serial_in)
	
proc_console_code SEGMENT CODE
	RSEG proc_console_code
		
proc_console:

	; no process active
	MOV R0, #0x00
	; use bitmask to determine active processes (up to 8)

	loop:
	
		SETB WDT
		SETB SWDT
		
		LCALL serial_in
		
		MOV A,B
		
		JNB F0, loop
			
			check_a:
				CJNE A, #'a', check_b
				
				MOV A, R0
				
				JB ACC.0, loop
				
				SETB ACC.0
				MOV R0, A
				
				CLR ET0
				
				NOP
				NOP
				
				SETB ET0
				JMP loop;
			
			check_b:
			
				NOP
				NOP
				
				JMP loop
				

				
			
			
			
			
			

	
END		
