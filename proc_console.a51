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

MOV R0, #0x00				; Init proc_z: 0x00 -> no process

	loop:

		SETB WDT 			;Turn-off Watchdog
		SETB SWDT
		
		LCALL serial_in		;get serial input
		MOV A,B				;load Input in ACC
		JNB F0, loop		;if no input was read loop
			
			check_a:
				CJNE A, #'a', check_b	;check if "a", else jump
				
				CLR ET0					;disable scheduler interrupt
				;;;;
				;preparation for new process
				;can't be interrupted
				;;;;
				MOV DPTR, #proc_a		;start adress of proc_a
				MOV PRC_ADR_L, DPL		;pass low byte
				MOV PRC_ADR_H, DPH		;pass high byte
				MOV PROC_TYPE_ID, #ID_A ;pass id of proc_a
				MOV PRIO, #0x01			;pass prio of proc_a
				MOV PROC_ALIVE, #0x01	;pass status alive
				
				LCALL new_proc			;add new process			
				SETB ET0				;enable scheduler interrupt
				
				JMP loop				;wait for input
			
			check_b:
				CJNE A, #'b', check_c	;check if "b", else jump
			
				CLR ET0					;disable scheduler interrupt
				;;;;
				;preparation for new process
				;can't be interrupted
				;;;;
				MOV DPTR, #proc_b		;start address of proc_b
				MOV PRC_ADR_L, DPL		;pass low byte
				MOV PRC_ADR_H, DPH		;pass high byte
				MOV PROC_TYPE_ID, #ID_B	;pass id of proc_b
				MOV PRIO, #0x01			;pass prio of proc_b
				MOV PROC_ALIVE, #0x01	;pass status alive
				
				LCALL new_proc			;add new process		
				SETB ET0				;enable scheduler interrupt			
				
				JMP loop				;wait for input
			
			check_c:
				CJNE A, #'c', check_z	;check if "c", else jump
				
				CLR ET0
				;;;;
				;search for existing proc b
				;if found delete, if not withdraw
				;;;;	
				MOV DPL, PROC_TABLE_L 	;start adress process table
				MOV DPH, PROC_TABLE_H
				
				
				MOV R7, #19 			;counter 20 process places
				JMP search_proc_type	;enter search loop
				
				continue_loop:			
					INC DPTR			
					DEC R7
					MOV A, R7
		
				JZ not_found			;end of loop if R7==0
		
				search_proc_type:
					INC DPTR		;2nd byte
					INC DPTR		;3rd byte			
					
					MOVX A, @DPTR	;get proc status byte (bitmask)
					ANL A, #0x07	;extract the PROC_TYPE_ID (bit:0,1,2)
					INC DPTR		;4th byte
			
					CJNE A, #ID_B, continue_loop ;jump if "b" wasn't found
			
				proc_type_found:	;found proc_b
				
					MOVX A, @DPTR	;get PID from 4th byte
					MOV PID, A		;pass PID			
					LCALL del_proc	;delete this process
					
				not_found:			;no "b" was found -> withdraw command
				SETB ET0 			;enable scheduler interrupt
				
				JMP loop			;wait for input
				
			check_z:
				CJNE A, #'z', loop 
				CLR ET0	
				;;;;
				;preparation for new process
				;can't be interrupted
				;;;;				
				MOV A, R0 	;get status of proc_z
				
				CJNE A, #0x00, end_z	;if z exists -> delete
				JMP start_z				;start z
				
				start_z:					
					MOV DPTR, #proc_z		;address of proc_b
					MOV PRC_ADR_L, DPL		;pass low byte
					MOV PRC_ADR_H, DPH		;pass hight byte
					MOV PROC_TYPE_ID, #ID_Z	;pass process type
					MOV PRIO, #0x03			;pass process prio
					MOV PROC_ALIVE, #0x01	;pass status alive
					
					LCALL new_proc			;add new process
					
					;;;;
					;set proc z existing
					;;;;
					MOV DPL, TMP_DPL		;get the address of the new process
					MOV DPH, TMP_DPH
					INC DPTR				;2nd byte
					INC DPTR				;3rd byte
					INC DPTR				;4th byte
					MOVX A, @DPTR 			;get the PID of the new process
					MOV R0, A 				;save the PID of the new process
					JMP finish
					
				
				end_z:
					MOV PID, R0		;get PID of proc_z
					MOV R0, #0x00	;reset status of proc_z
					LCALL del_proc	;del proc_z
				
				finish:
				SETB ET0	; enable scheduler interrupt
				
				JMP loop
	
END		
