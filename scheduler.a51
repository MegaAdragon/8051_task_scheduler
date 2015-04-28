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
	
	proc_table: DS 40 ; allocates space for process table (includes 20 processes)
		
	proc_data:  DS 640 ; allocates space to save process context (20 * 32Byte)
	
scheduler_code SEGMENT CODE
	RSEG scheduler_code
		


scheduler_init:
NOP
NOP
	

RET


new_proc:
	
	SETB PSW.4
	
	MOV R0, A
	MOV R1, B
	MOV R2, DPL
	MOV R3, DPH
	
	MOV DPTR, #proc_table
	MOV R7, #19
	
	search_empty:	
		; LOW-Byte
		MOVX A, @DPTR 	
	
		MOV TMP_DPL, DPL
		MOV TMP_DPH, DPH
		INC DPTR
		JZ check_high_byte	
		
		INC DPTR
		
	DJNZ R7, search_empty
	JMP no_space
	
	check_high_byte:
			; HIGH-Byte
			
			MOVX A, @DPTR
			JZ empty_space_found
	RET
	
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
		
		; write priority
		MOV A, PRIO
		MOVX @DPTR, A
		
		MOV A, DPL
		ADD A, #13
		MOV DPL, A
		
		;check overflow 
		; set data
		
		
		NOP
		NOP
		
		
		
		; insert adress in proc_table
		MOV DPL, TMP_DPL
		MOV DPH, TMP_DPH
		
		MOV A, R4
		MOVX @DPTR, A
		INC DPTR
		MOV A, R5
		MOVX @DPTR, A	

		NOP
	
	no_space:	
		NOP
		NOP
	RET
	
	
	del_proc:
		NOP
		NOP

	change_proc:
		NOP
		NOP
END	