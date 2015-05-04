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
		
	proc_data:  DS 640 ; allocates space to save process context (20 * 32Byte)
	
scheduler_code SEGMENT CODE
	RSEG scheduler_code
		


scheduler_init:
	MOV DPTR, #proc_table
	MOV PROC_TABLE_L, DPL
	MOV PROC_TABLE_H, DPH
	MOV PROC_TABLE_INDEX, #20
RET


;;SUBROUTINE <----NEW PROCESS---->
;
;
;
new_proc:
	
	SETB PSW.3						;Switch to registry bank #2
	SETB PSW.4
	
	MOV R0, A						;saving from A,B,DPTR
	MOV R1, B
	MOV R2, DPL
	MOV R3, DPH
	;get the start adress of process table containing adresses of according data
	MOV DPTR, #proc_table
	; 20 processes in total can be managed
	MOV R7, #19 
	
	;LOOP - SEARCH free space
	;determine if there is a free spot in process table 
	;first free spot will be used to create new process
	;free spot contains 0x00h as a value in DPL && DPH
	search_empty:
	
		;get DPL of proc_data
		MOVX A, @DPTR
		;save the adress
		MOV TMP_DPL, DPL
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
				
				;subcondition nof LOOP search free space		
				check_high_byte:
						; HIGH-Byte
						
						MOVX A, @DPTR
						JZ empty_space_found
				RET
				
	;NEW PROCESS WILL BE CREATED HERE
	;there are 20 slot 32 bytes each reserved for proc data
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

		ADD A,R4
		MOV R4, A
		MOV A, DPH
		ADDC A, R5
		MOV R5, A
		
		; write data
		MOV DPL, R4
		MOV DPH, R5

		MOV R6, #31
		clean_space:
			MOV A, 0x00
			MOVX @DPTR, A
			INC DPTR
		DJNZ R6, clean_space
		
		MOV DPL, R4
		MOV DPH, R5
		
		MOV A, DPL
		ADD A, #13
		MOV DPL, A
		
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
		
		;set start Adress of the new process in it´s DPTR
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
		
	MOV A,R0						;restoring A,B,DPTR
	MOV B,R1
	MOV DPL,R2
	MOV DPH,R3
	
	CLR PSW.3   					;switch back to registry bank 1
	CLR PSW.4
	RET
;; END SUBROUTINE <----NEW PROCESS---->
	
	del_proc:
	
		SETB PSW.3						;Switch to registry bank #3
		SETB PSW.4
	
		MOV R0, A						;saving from A,B,DPTR
		MOV R1, B
		MOV R2, DPL
		MOV R3, DPH
		;get the start address of process table containing adresses of according data
		MOV DPTR, #proc_table
		; 20 processes in total can be managed
		MOV R7, #19 
		JMP search_pid
		
		; Loop to search ID
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
			
			CJNE A, PID, continue_loop
			
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
		MOV A,R0						;restoring A,B,DPTR
		MOV B,R1
		MOV DPL,R2
		MOV DPH,R3
	
		
		CLR PSW.3   					;switch back to registry bank 1
		CLR PSW.4
			
	RET
	
	dec_dptr:
		DEC DPL
		MOV R6, DPL
		CJNE R6, #0xFF, SKIP
		DEC DPH
		SKIP:
	RET

	change_proc:
	
	CLR ET0
	
		POP TMP_LCALL_L
		POP TMP_LCALL_H
	
		MOV TMP_PSW, PSW
		
		SETB PSW.3						;Switch to registry bank #2
		SETB PSW.4
	
		MOV R0, A						;saving from A,B,DPTR
		MOV R1, B
		MOV R2, DPL
		MOV R3, DPH
		
		MOV R7, PROC_TABLE_INDEX	
				
		MOV A, #4
		MOV B, R7
		MUL AB
		
		MOV R4, A		
		
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
		MOV A, R4
		JZ check_high
		JMP write_data
		check_high:
		MOV A, R5
		JZ get_next_process
		
		write_data:
		
		MOV DPL, R4
		MOV DPH, R5		
		
		; DPL		
		MOV A, R2
		MOVX @DPTR, A
		
		; DPH
		INC DPTR
		MOV A, R3
		MOVX @DPTR, A
		
		; PSW
		INC DPTR
		MOV A, TMP_PSW
		MOVX @DPTR, A
		
		; B
		INC DPTR
		MOV A, R1
		MOVX @DPTR, A
		
		; A
		INC DPTR
		MOV A, R0
		MOVX @DPTR, A
		
		CLR PSW.3
		CLR PSW.4
		
		; R0
		INC DPTR
		MOV A, R0
		MOVX @DPTR, A
		
		; R1
		INC DPTR
		MOV A, R1
		MOVX @DPTR, A
		
		; R2
		INC DPTR
		MOV A, R2
		MOVX @DPTR, A
		
		; R3
		INC DPTR
		MOV A, R3
		MOVX @DPTR, A
		
		; R4
		INC DPTR
		MOV A, R4
		MOVX @DPTR, A
		
		; R5
		INC DPTR
		MOV A, R5
		MOVX @DPTR, A
		
		; R6
		INC DPTR
		MOV A, R6
		MOVX @DPTR, A
		
		; R7
		INC DPTR
		MOV A, R7
		MOVX @DPTR, A
		
		; SP
		INC DPTR
		MOV A, SP
		MOVX @DPTR, A
		
		MOV R0, #0x00	
		
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
		
		get_next_process:
		
			MOV A, TMP_DPL
			MOV DPTR, #proc_table
			MOV R0, DPL
			CJNE A, 0x00, select_next_process
			MOV A, TMP_DPH
			MOV R0, DPH
			CJNE A, 0x00, select_next_process
			
			MOV A, #4
			MOV B, #20
			MUL AB
		
			MOV R4, A		
			
			MOV DPTR, #proc_table
			; LOW-Byte
			MOV A, DPL
			ADD A,R4
			MOV DPL, A
			
			MOV PROC_TABLE_INDEX, #20			
			
			JNC get_data
				INC DPH			
			
			JMP get_data
			
			select_next_process:
				MOV DPL, TMP_DPL
				MOV DPH, TMP_DPH
				LCALL dec_dptr
				LCALL dec_dptr
				LCALL dec_dptr
				LCALL dec_dptr
				DEC PROC_TABLE_INDEX
			
			get_data:
		
				SETB PSW.3						;Switch to registry bank #3
				SETB PSW.4
				
				MOV TMP_DPL, DPL
				MOV TMP_DPH, DPH
		
				MOVX A, @DPTR
				INC DPTR
				MOV R4, A
				MOVX A, @DPTR
				MOV R5, A
				
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

				CLR PSW.3
				CLR PSW.4
								
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
				
								
				SETB PSW.3						;Switch to registry bank #3
				SETB PSW.4		
				
				
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
					MOV DPL, R4
					MOV DPH, R5
					MOV A, R6
					MOV PSW, TMP_PSW
					
					MOV PROC_ALIVE, #0x01
					
					
					PUSH TMP_LCALL_H
					PUSH TMP_LCALL_L
					SETB ET0
		RET
		
END	