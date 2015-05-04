$NOMOD51
NAME proc_console
; module for console process

#include <Reg517a.inc>
#include "variables.inc"

PUBLIC proc_console
EXTRN CODE (serial_in)
EXTRN CODE (new_proc)
EXTRN CODE (del_proc)
EXTRN CODE (proc_a)
EXTRN CODE (proc_b)
EXTRN CODE (proc_z)
	
proc_console_code SEGMENT CODE
	RSEG proc_console_code
		
proc_console:

	MOV R0, #0x00 ; save status of z

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
				MOV PROC_TYPE_ID, #ID_A
				MOV PRIO, #0x01
				MOV PROC_ALIVE, #0x01
				LCALL new_proc	
			
				
				SETB ET0
				JMP loop
			
			check_b:
			
				CJNE A, #'b', check_c
			
				CLR ET0
				MOV DPTR, #proc_b
				MOV PRC_ADR_L, DPL
				MOV PRC_ADR_H, DPH	
				MOV PROC_TYPE_ID, #ID_B
				MOV PRIO, #0x05
				MOV PROC_ALIVE, #0x01
				LCALL new_proc				
				
				SETB ET0				
				
				JMP loop
			
			check_c:
				CLR ET0
				
				CJNE A, #'c', check_z
				
				MOV DPL, PROC_TABLE_L
				MOV DPH, PROC_TABLE_H
				; 20 processes in total can be managed
				MOV R7, #19 
				JMP search_proc_type
				
				continue_loop:
					INC DPTR
					DEC R7
					MOV A, R7
		
				JZ not_found
		
				search_proc_type:
					INC DPTR
					INC DPTR					
					
					MOVX A, @DPTR
					ANL A, #0x07
					INC DPTR
			
					CJNE A, #ID_B, continue_loop
			
				proc_type_found:
					
					MOVX A, @DPTR
					
					MOV PID, A				
				
					LCALL del_proc
					
				not_found:
				SETB ET0
				
				JMP loop
				
			check_z:
				CLR ET0
				
				CJNE A, #'z', loop
				
				MOV A, R0
				
				CJNE A, #0x00, end_z
				JMP start_z
				
				start_z:
					MOV DPTR, #proc_z
					MOV PRC_ADR_L, DPL
					MOV PRC_ADR_H, DPH	
					MOV PROC_TYPE_ID, #ID_Z
					MOV PRIO, #0x05
					MOV PROC_ALIVE, #0x01
					LCALL new_proc
					MOV DPL, TMP_DPL
					MOV DPH, TMP_DPH
					INC DPTR
					INC DPTR
					INC DPTR
					MOVX A, @DPTR
					MOV R0, A
					JMP finish
					
				
				end_z:
					MOV PID, R0
					MOV R0, #0x00
					LCALL del_proc
				
				finish:
				SETB ET0
				
				JMP loop
	
END		
