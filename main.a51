$NOMOD51
	
#include <Reg517a.inc>
#include "variables.inc"

EXTRN CODE (serial_init)
EXTRN CODE (proc_console)

ORG 0
JMP main

ORG 0x0b
JMP timer0_intr

main:

	LCALL serial_init
	
	MOV DPTR, #proc_console
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH
	MOV PRIO, #0x02
	LCALL new_process
	
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
	
	
timer0_intr_fin:
RETI 

END