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

MOV R0, #0x00	; Init proc_z: 0x00 -> no process

	loop:

		SETB WDT 					;Turn-off Watchdog
		SETB SWDT
		
		LCALL serial_in				; get serial input
		
		MOV A,B
		
		JNB F0, loop
			
			check_a:
				CJNE A, #'a', check_b
				
				CLR ET0	; disable scheduler interrupt
				MOV DPTR, #proc_a	; set parameter for start address in proc_a
				MOV PRC_ADR_L, DPL
				MOV PRC_ADR_H, DPH	
				MOV PROC_TYPE_ID, #ID_A ; set parameter for PROC_TYPE_ID
				MOV PRIO, #0x01
				MOV PROC_ALIVE, #0x01
				LCALL new_proc	; add new process			
				
				SETB ET0	; enable scheduler interrupt
				JMP loop
			
			check_b:
			
				CJNE A, #'b', check_c
			
				CLR ET0	; disable scheduler interrupt
				MOV DPTR, #proc_b	; set parameter for start address in proc_b
				MOV PRC_ADR_L, DPL
				MOV PRC_ADR_H, DPH	
				MOV PROC_TYPE_ID, #ID_B	; set parameter for PROC_TYPE_ID
				MOV PRIO, #0x01
				MOV PROC_ALIVE, #0x01
				LCALL new_proc	; add new process		
				
				SETB ET0	; enable scheduler interrupt			
				
				JMP loop
			
			check_c:
				CLR ET0
				
				CJNE A, #'c', check_z
				
				MOV DPL, PROC_TABLE_L ; get start address of process table
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
					
					MOVX A, @DPTR	; get the process status byte from the current process
					ANL A, #0x07	; extract the PROC_TYPE_ID from the process status byte  
					INC DPTR
			
					CJNE A, #ID_B, continue_loop ; match PROC_TYPE_ID on ID_B
			
				proc_type_found:	; found proc_b
				
					MOVX A, @DPTR	; get PID
					MOV PID, A					
					LCALL del_proc	; delete this process
					
				not_found:
				SETB ET0 ; enable scheduler interrupt
				
				JMP loop
				
			check_z:
				CLR ET0
				
				CJNE A, #'z', loop
				
				MOV A, R0 ; get status of proc_z
				
				CJNE A, #0x00, end_z ; check if proc_z already exists
				JMP start_z
				
				start_z:					
					MOV DPTR, #proc_z	; set parameter for start address in proc_b
					MOV PRC_ADR_L, DPL
					MOV PRC_ADR_H, DPH	
					MOV PROC_TYPE_ID, #ID_Z	; set parameter for PROC_TYPE_ID
					MOV PRIO, #0x05
					MOV PROC_ALIVE, #0x01
					LCALL new_proc	; add new process
					
					MOV DPL, TMP_DPL	; get the address of the new process
					MOV DPH, TMP_DPH
					INC DPTR
					INC DPTR
					INC DPTR
					MOVX A, @DPTR ; get the PID of the new process
					MOV R0, A 	; save the PID of the new process
					JMP finish
					
				
				end_z:
					MOV PID, R0	; get PID of proc_z
					MOV R0, #0x00	; reset status of proc_z
					LCALL del_proc	; del proc_z
				
				finish:
				SETB ET0	; enable scheduler interrupt
				
				JMP loop
	
END		
