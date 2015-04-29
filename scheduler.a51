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
	
	proc_table: DS 60 ; allocates space for process table (includes 20 processes)
		
	proc_data:  DS 640 ; allocates space to save process context (20 * 32Byte)
	
scheduler_code SEGMENT CODE
	RSEG scheduler_code
		


scheduler_init:
NOP
NOP
RET


;;SUBROUTINE <----NEW PROCESS---->
;
;
;
new_proc:
	
	SETB PSW.4						;Switch to registry bank #2
	
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
		
		
		MOV A, DPL
		ADD A, #12
		MOV DPL, A
		
		;check overflow
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
		INC DPTR
		
		;set start Adress of the new process in it´s DPTR
		MOV A, #START_ADRL
		MOVX @DPTR, A
		
		INC DPTR
		
		MOV A, #START_ADRH
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
		
		; Write PID
		ORL A, PROC_TYPE_ID
		
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
	
	CLR PSW.4   					;switch back to registry bank 1
	RET
;; END SUBROUTINE <----NEW PROCESS---->
	
	del_proc:
	
		SETB PSW.4						;Switch to registry bank #2
	
		MOV R0, A						;saving from A,B,DPTR
		MOV R1, B
		MOV R2, DPL
		MOV R3, DPH
		;get the start adress of process table containing adresses of according data
		MOV DPTR, #proc_table
		; 20 processes in total can be managed
		MOV R7, #19 
		JMP search_type_id
		
		; Loop to search ID
		continue_loop:
		INC DPTR
		DEC R7
		MOV A, R7
		
		JZ not_found
		
		search_type_id:
			INC DPTR
			INC DPTR			
			MOVX A, @DPTR
			ANL A, #7
			
			CJNE A, PROC_TYPE_ID, continue_loop
			
			id_found:
				MOV A, 0x00
				MOVX @DPTR, A
				
				LCALL dec_dptr

				MOVX @DPTR, A
				
				LCALL dec_dptr
				
				MOVX @DPTR, A
		
		
		not_found:
		MOV A,R0						;restoring A,B,DPTR
		MOV B,R1
		MOV DPL,R2
		MOV DPH,R3
	
		CLR PSW.4   					;switch back to registry bank 1
	RET
	
	dec_dptr:
		DEC DPL
		MOV R6, DPL
		CJNE R6, #0xFF, SKIP
		DEC DPH
		SKIP:
	RET

	change_proc:
		NOP
		NOP
END	