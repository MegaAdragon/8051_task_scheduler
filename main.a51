$NOMOD51
	
#include <Reg517a.inc>
#include "variables.inc"

EXTRN CODE (serial_init)
EXTRN CODE (proc_console)
EXTRN CODE (scheduler_init)
EXTRN CODE (new_proc)
EXTRN CODE (del_proc)
EXTRN CODE (change_proc)

ORG 0
JMP main

ORG 0x0b
JMP timer0_intr

ORG 0x1b
JMP timer1_intr

main:	
		
	LCALL serial_init
	LCALL scheduler_init	
	
	; add new process for console
	MOV DPTR, #proc_console
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH	
	MOV PROC_TYPE_ID, #ID_CON
	MOV PRIO, #0x05
	MOV PROC_ALIVE, #0x01
	LCALL new_proc
		
	SETB EAL	; enable interrupts	
	SETB ET0	; enable timer 0 interrupt
	SETB ET1	; enable timer 1 interrupt
	SETB TR0	; start timer 0
	SETB TR1	; start timer 1
	ORL TMOD, #0x11	; set timer mode (timer 0 and timer 1 in 16Bit mode)
	MOV TL0, #INIT_TL0	; init timer 0
	MOV TH0, #INIT_TH0
	MOV TL1, #INIT_TL1	; init timer 1
	MOV TH1, #INIT_TH1
	MOV TIMER1_CNT, #40 ; init counter for timer 1 (40*25ms = 1s)
	
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
	
	CJNE A, #0x00, get_prio	; check if process is alive
		
		MOV DPL, TMP_DPL	; get address of the current process
		MOV DPH, TMP_DPH
		
		INC DPTR	; goto PID
		INC DPTR
		INC DPTR

		; get PID
		MOVX A, @DPTR
		MOV PID, A
		
		LCALL change_proc
		
		LCALL del_proc
		
		JMP timer0_intr_fin		
		
	get_prio:
		MOV DPL, TMP_DPL	; get address of the current process
		MOV DPH, TMP_DPH		
		
		INC DPTR	; goto process status byte
		INC DPTR
		
		;get PRIO (first 3 bit)
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
		MOVX @DPTR, A	; write PRIO back to process status byte
		
		
	timer0_intr_fin:		
	RETI 
	
	
	timer1_intr:
		MOV TL1, #INIT_TL1	; reset timer
		MOV TH1, #INIT_TH1
		DJNZ TIMER1_CNT, timer1_intr_fin ; check if 1s has passed
			INC SECONDS_TIMER
			MOV TIMER1_CNT, #40
		
	timer1_intr_fin:
	RETI

END