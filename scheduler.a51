$NOMOD51
name scheduler
; module to manage processes

#include <Reg517a.inc>
#include "variables.inc"

PUBLIC scheduler_init
PUBLIC new_proc
PUBLIC del_proc
PUBLIC change_proc
	
	proc_table_data SEGMENT XDATA
		RSEG proc_table_data
	
	proc_table: DS 80 ; allocates space for process table (includes 20 processes)
					  ; each process gets 4 Byte
					  ; Byte 1 -> adress of process data (low)
					  ; Byte 2 -> adress of process data (high)
					  ; Byte 3 -> process status byte, contains PRIO (first 3 Bit) and PROC_TYPE_ID
					  ; Byte 4 -> PID
		
	proc_data:  DS 640 ; allocates space to save process context (20 * 32Byte)
					   ; 13 Byte for process data
					   ; 10 Byte for process stack
					   ; more space is possible
	
scheduler_code SEGMENT CODE
	RSEG scheduler_code

scheduler_init:
	MOV DPTR, #proc_table
	MOV PROC_TABLE_L, DPL	; set proc_table address to global variable (for access in other modules)
	MOV PROC_TABLE_H, DPH
	MOV PROC_TABLE_INDEX, #20	; init PROC_TABLE_INDEX on last position
RET


;;SUBROUTINE <----NEW PROCESS---->
new_proc:

	; save data from current process	
    LCALL save_current_proc
	
	MOV DPTR, #proc_table	; get the start adress of process table containing adresses of according data
	; 20 processes in total can be managed
	MOV R7, #19 
	
	;LOOP - SEARCH free space
	;determine if there is a free spot in process table 
	;first free spot will be used to create new process
	;free spot contains 0x00h as a value in DPL && DPH
	search_empty:
	
		MOVX A, @DPTR	;get DPL of proc_data
		
		MOV TMP_DPL, DPL	;save the address
		MOV TMP_DPH, DPH
		
		;check if DPL && DPH for data is 0x00
		;free spot found
		INC DPTR
		JZ check_high_byte	
		
		INC DPTR
		INC DPTR
		INC DPTR
		
	DJNZ R7, search_empty
	;END OF LOOP
	JMP no_space
				
				;subcondition of LOOP search free space		
				check_high_byte:
						; HIGH-Byte
						
						MOVX A, @DPTR
						JZ empty_space_found
				RET
				
	;NEW PROCESS WILL BE CREATED HERE
	;there are 20 slots with 32 bytes each reserved for proc data
	empty_space_found:
	
		; calc the new offset in proc_data		
		MOV A, #32
		MOV B, R7
		MUL AB
		
		MOV R4, A
		MOV R5, B
		
		MOV DPTR, #proc_data
		; LOW-Byte
		MOV A, DPL

		; add offset to DPTR
		ADD A,R4
		MOV R4, A
		MOV A, DPH
		ADDC A, R5
		MOV R5, A
		
		; write data
		MOV DPL, R4
		MOV DPH, R5

		; loop through process data and reset all values
		MOV R6, #31
		clean_space:
			MOV A, 0x00
			MOVX @DPTR, A
			INC DPTR
		DJNZ R6, clean_space
		
		MOV DPL, R4
		MOV DPH, R5
		
		; add offset for process data
		MOV A, DPL
		ADD A, #PROC_DATA_OFFSET
		MOV DPL, A
		
		; save SP
		JNC save_SP
			INC DPH
		
		
		; new process has an empty stack, so SP = 0x07h
		; there was a LCALL before - there is a DPL/DPH on the stack
		; --> SP = SP + 2 for every new process
		save_SP:
			MOV A,#0x09
			MOVX @DPTR,A

		; set data - new process - start adress will be placed on its stack
		INC DPTR
		
		; put start adress of the new process on it´s stack
		MOV A, PRC_ADR_L
		MOVX @DPTR, A
		
		INC DPTR
		
		MOV A, PRC_ADR_H
		MOVX @DPTR, A
		
		
		; insert adress in proc_table
		; here we can set the adress pointing to data
		MOV DPL, TMP_DPL
		MOV DPH, TMP_DPH
		
		MOV A, R4
		MOVX @DPTR, A
		INC DPTR
		MOV A, R5
		MOVX @DPTR, A	
		
		; set process status byte
		INC DPTR
		; write priority
		MOV A, PRIO
		RR A
		RR A
		RR A
		
		; Write PROC_TYPE_ID
		ORL A, PROC_TYPE_ID
		
		MOVX @DPTR, A
		
		INC DPTR
		MOV A, R7
		MOVX @DPTR, A

		JMP restore_after_new

	; if no free space is found process will be withdrawn 
	; MESSAGE ???
	no_space:
	restore_after_new:
	
	; restore process data
	LCALL restore_proc
	RET
	;; END SUBROUTINE <----NEW PROCESS---->
	
	del_proc:
		; save data from current process
		LCALL save_current_proc
		
		;get the start address of process table containing adresses of according data
		MOV DPTR, #proc_table
		; 20 processes in total can be managed
		MOV R7, #19 
		JMP search_pid
		
		; Loop to search PID
		continue_loop:
		INC DPTR
		DEC R7
		MOV A, R7
		
		JZ not_found
		
		search_pid:
			INC DPTR
			INC DPTR
			INC DPTR
			MOVX A, @DPTR			
			
			CJNE A, PID, continue_loop ; check if the current PID is the searched PID
			
			id_found:
				; write #0x00 in PID
				MOV A, #0x00
				MOVX @DPTR, A
				
				; write #0x00 in ROC_TYPE_ID
				LCALL dec_dptr				
				MOVX @DPTR, A
				
				; write #0x00 in adress high byte
				LCALL dec_dptr
				MOVX @DPTR, A
				
				; write #0x00 in address low byte
				LCALL dec_dptr				
				MOVX @DPTR, A
		
		
		not_found:
		; restore process data
		LCALL restore_proc
		MOV PROC_ALIVE, #0x01
			
	RET

	change_proc:
	
		CLR ET0
	
		POP TMP_LCALL_L	; push address for return on stack
		POP TMP_LCALL_H	
		
		LCALL save_current_proc	; save data from current process
		
		MOV R7, PROC_TABLE_INDEX	
		
		; calcute position in process table
		MOV A, #4
		MOV B, R7
		MUL AB
		
		MOV R4, A		
		
		; set DPTR to calculated position
		MOV DPTR, #proc_table
		; LOW-Byte
		MOV A, DPL
		ADD A,R4
		MOV DPL, A
		
		JNC no_overflow
			INC DPH
		
		no_overflow:
		
		MOV TMP_DPL, DPL
		MOV TMP_DPH, DPH
		
		MOVX A, @DPTR
		MOV R4, A		
		INC DPTR		
		MOVX A, @DPTR
		MOV R5, A
		
		; check if process selected
		; if you call change_proc for the first time, this will skip write_data
		MOV A, R4
		JZ check_high
		JMP write_data
		check_high:
		MOV A, R5
		JZ get_next_process
		
		; save data of current process
		write_data:
		
		MOV DPL, R4
		MOV DPH, R5		
		
		MOV R1, #TMP_PROC_DATA
		
		; write the data of the current process
		; current data is saved in user ram
		write_current_data:
			MOV A, @R1
			MOVX @DPTR, A
			INC R1
			INC DPTR
		CJNE R1, #TMP_PROC_DATA+13, write_current_data	; check if position in user ram has reached offset
		
		; SP
		MOV A, SP
		MOVX @DPTR, A
		
		MOV R0, #0x00	
		
		; stack
		copy_stack:
			MOV A, R0
			
			CJNE A, #10, write_stack
				JMP get_next_process
			
			write_stack:
				INC R0
				INC DPTR
				
				ADD A, #0x07
				INC A
				
				MOV R1, A
				MOV A, @R1
				
				MOVX @DPTR, A
				
				JMP copy_stack
		
		; search the next process in process table
		get_next_process:
		
			MOV A, TMP_DPL
			MOV DPTR, #proc_table
			MOV R0, DPL
			; if address = 0 -> end of table reached -> goto opposite side table
			CJNE A, 0x00, select_next_process
			MOV A, TMP_DPH
			MOV R0, DPH
			CJNE A, 0x00, select_next_process
		
			MOV R4, #80	; max size of the table	
			
			;add max_size to proc_table
			MOV DPTR, #proc_table
			; LOW-Byte
			MOV A, DPL
			ADD A,R4
			MOV DPL, A
			
			; current position is now at the top of the table
			MOV PROC_TABLE_INDEX, #20			
			
			JNC get_data
				INC DPH			
			
			JMP get_data
			
			; decrement to next process
			select_next_process:
				MOV DPL, TMP_DPL
				MOV DPH, TMP_DPH
				LCALL dec_dptr
				LCALL dec_dptr
				LCALL dec_dptr
				LCALL dec_dptr
				DEC PROC_TABLE_INDEX
			
			get_data:
				
				MOV TMP_DPL, DPL
				MOV TMP_DPH, DPH
		
				MOVX A, @DPTR
				INC DPTR
				MOV R4, A
				MOVX A, @DPTR
				MOV R5, A
				
				; check if there is data in the current position -> if not, take next process
				JNZ continue_get_data
				MOV A, R4
				JNZ continue_get_data
				JMP get_next_process
				
				continue_get_data:
				MOV DPL, R4
				MOV DPH, R5								
				
				; DPL								
				MOVX A, @DPTR
				MOV R4, A 
				
				; DPH
				INC DPTR				
				MOVX A, @DPTR
				MOV R5, A
				
				; PSW
				INC DPTR				
				MOVX A, @DPTR
				MOV TMP_PSW, A
				
				; B
				INC DPTR				
				MOVX A, @DPTR
				MOV B, A
				
				; A
				INC DPTR				
				MOVX A, @DPTR	
				MOV R6, A
								
				; R0
				INC DPTR				
				MOVX A, @DPTR
				MOV R0, A
				
				; R1
				INC DPTR				
				MOVX A, @DPTR
				MOV R1, A
				
				; R2
				INC DPTR
				MOVX A, @DPTR
				MOV R2, A
				
				; R3
				INC DPTR
				MOVX A, @DPTR
				MOV R3, A
				
				; R4
				INC DPTR
				MOVX A, @DPTR
				MOV R4, A
				
				; R5
				INC DPTR
				MOVX A, @DPTR
				MOV R5, A
				
				; R6
				INC DPTR
				MOVX A, @DPTR
				MOV R6, A
				
				; R7
				INC DPTR
				MOVX A, @DPTR
				MOV R7, A
				
				; SP
				INC DPTR
				MOVX A, @DPTR
				MOV SP, A
				
				LCALL save_current_proc	; save loaded data as current process		
				
				MOV R0, #0x00
				
				get_stack:
					MOV A, R0
				
					CJNE A, #10, rewrite_stack
						JMP finish_rewrite
						
					rewrite_stack:
						INC R0
						INC DPTR
						
						ADD A, #0x07
						INC A
						
						MOV R1, A
						MOVX A, @DPTR
						MOV @R1, A
						
						JMP get_stack
						
				finish_rewrite:
					LCALL restore_proc	; restore process data				
					
					PUSH TMP_LCALL_H	; reset return adress on stack
					PUSH TMP_LCALL_L
					SETB ET0
		RET
		
		; sub routine to decrement DPTR
		dec_dptr:
			DEC DPL
			MOV R6, DPL
			CJNE R6, #0xFF, SKIP
			DEC DPH
			SKIP:
		RET
		
		; sub routine to save current process data in user ram
		; the data structure is equal to the specification in proc_data
		; to switch process context, you only have to copy the data from the user stack
		save_current_proc:
			MOV TMP_PROC_DATA, DPL
			MOV TMP_PROC_DATA+1, DPH
			MOV TMP_PROC_DATA+2, PSW
			MOV TMP_PROC_DATA+3, B
			MOV TMP_PROC_DATA+4, A
			MOV TMP_PROC_DATA+5, R0
			MOV TMP_PROC_DATA+6, R1
			MOV TMP_PROC_DATA+7, R2
			MOV TMP_PROC_DATA+8, R3
			MOV TMP_PROC_DATA+9, R4
			MOV TMP_PROC_DATA+10, R5	
			MOV TMP_PROC_DATA+11, R6
			MOV TMP_PROC_DATA+12, R7		
		RET
		
		; sub routine to restore saved process data from user stack
		restore_proc:
			MOV DPL, TMP_PROC_DATA
			MOV DPH, TMP_PROC_DATA+1
			MOV PSW, TMP_PROC_DATA+2
			MOV B, TMP_PROC_DATA+3
			MOV A, TMP_PROC_DATA+4
			MOV R0, TMP_PROC_DATA+5
			MOV R1, TMP_PROC_DATA+6
			MOV R2, TMP_PROC_DATA+7
			MOV R3, TMP_PROC_DATA+8
			MOV R4, TMP_PROC_DATA+9
			MOV R5, TMP_PROC_DATA+10	
			MOV R6, TMP_PROC_DATA+11
			MOV R7, TMP_PROC_DATA+12		
		RET
		
END	