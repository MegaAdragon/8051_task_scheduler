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

	MOV DPTR, #proc_console
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH
	MOV PROC_TYPE_ID, #ID_CON
	MOV PRIO, #0x02
	LCALL new_proc

	MOV DPTR, #proc_b
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH
	MOV PRIO, #5
	MOV PROC_TYPE_ID, #ID_B
	LCALL new_proc
	
	MOV DPTR, #proc_a
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH
	MOV PRIO, #2
	MOV PROC_TYPE_ID, #ID_A
	LCALL new_proc
	
	MOV PROC_TYPE_ID, #ID_A
	LCALL del_proc
		
	LCALL serial_init
	
	
	
	LCALL change_proc
	
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
		

timer0_intr:

	; reload timer
	MOV TL0, #INIT_TL0
	MOV TH0, #INIT_TH0
	
	MOV A, PROC_ALIVE
	
	CJNE A, #0x00, tgl_counter
		
		tgl_counter:
			NOP
			NOP
	
	
timer0_intr_fin:
RETI 

END