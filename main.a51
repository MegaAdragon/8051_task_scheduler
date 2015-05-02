$NOMOD51
	
#include <Reg517a.inc>
#include "variables.inc"

EXTRN CODE (serial_init)
EXTRN CODE (proc_console)
EXTRN CODE (proc_a)
EXTRN CODE (proc_b)
EXTRN CODE (scheduler_init)
EXTRN CODE (new_proc)
EXTRN CODE (del_proc)
EXTRN CODE (change_proc)

ORG 0
JMP main

ORG 0x0b
JMP timer0_intr

main:

	
		
	LCALL serial_init
	LCALL scheduler_init	
	
	MOV DPTR, #proc_console
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH	
	MOV PROC_TYPE_ID, #ID_CON
	MOV PRIO, #0x02
	MOV PROC_ALIVE, #0x01
	LCALL new_proc
		
	SETB EAL
	SETB ET0
	SETB TR0
	ORL TMOD, #0x01
	MOV TL0, #INIT_TL0
	MOV TH0, #INIT_TH0
	
	loop:
		SETB WDT
		SETB SWDT
		
		JMP loop
		

;;TODO:
; check if it is save to use TMP_DPL & TMP_DPH

; change_proc only works in ISR
; adress for RETI comes from process stack
; RETI goes to selected process

timer0_intr:	

	; reload timer
	MOV TL0, #INIT_TL0
	MOV TH0, #INIT_TH0	
	
	MOV A, PROC_ALIVE
	
	CJNE A, #0x00, get_prio
		
		; get PROC_TYPE_ID
		MOV DPL, TMP_DPL
		MOV DPH, TMP_DPH
		
		INC DPTR
		INC DPTR
		
		; TODO: PROC_TYPE_ID is not explicit
		
		MOVX A, @DPTR
		ANL A, #0x07
		
		MOV PROC_TYPE_ID, A
		
		;LCALL del_proc
	
		LCALL change_proc
		
	get_prio:
		MOV DPL, TMP_DPL
		MOV DPH, TMP_DPH		
		
		INC DPTR
		INC DPTR
		
		;get PRIO
		MOVX A, @DPTR
		ANL A, #0xE0
		RL A
		RL A
		RL A
		
		MOV PRIO, A
		
		DJNZ PRIO, write_prio
			LCALL change_proc
		JMP timer0_intr_fin
			
	
	
	write_prio:
		MOV A, PRIO
		RR A
		RR A
		RR A
		MOV PRIO, A
		MOVX A, @DPTR
		ANL A, #0x1F
		ORL A, PRIO
		MOVX @DPTR, A
		
	timer0_intr_fin:
	RETI 

END