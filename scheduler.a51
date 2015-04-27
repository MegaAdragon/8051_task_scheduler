$NOMOD51
name scheduler
; module to manage processes

#include <Reg517a.inc>
#include "variables.inc"

PUBLIC scheduler_init
PUBLIC new_proc
PUBLIC del_proc
PUBLIC change_proc
	
scheduler_code SEGMENT CODE
	RSEG scheduler_code

scheduler_init:

	MOV PROC_CNT, #0x00
	MOV CURRENT_PID, #-1

RET


new_proc:
	
	; save current data
	MOV R0, A
	MOV R1, B
	MOV R2, DPH
	MOV R3, DPL
	
	MOV A, PROC_CNT
	
	;new PID
	MOV R4, A
	MOV RETURN, A
	
	INC PROC_CNT
	
	; calc new adresses
	MOV B, #PROC_SIZE
	MUL AB
	MOV DPL, A
	MOV DPH, B
	
	MOV A, PRIO
	MOVX @DPTR, A
	
	; WHY OFFSET??
	MOV A, DPL
	ADD A, #PROC_OFFSET
	MOV DPL, A
	
	NOP 
	NOP
	
	MOV A, R0
	MOV B, R1
	MOV DPH, R2
	MOV DPL, R3
	
	