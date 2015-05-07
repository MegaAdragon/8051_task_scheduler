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
	MOV DPTR, #proc_console  ;process begin adress
	MOV PRC_ADR_L, DPL
	MOV PRC_ADR_H, DPH	
	MOV PROC_TYPE_ID, #ID_CON ;process type identifier
	MOV PRIO, #0x05 ; 5 time slices priority
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
	
	; main loop
	loop:
		SETB WDT
		SETB SWDT
		
		JMP loop
	;end main loop
		

	; address for RETI comes from process stack
	; RETI goes into current process

	;;BEGIN TIMER_1 INTERRUPT HANDLING
	;
	;
	
	timer0_intr:	
		
		MOV TL0, #INIT_TL0 ; reload timer
		MOV TH0, #INIT_TH0			
				
		
		MOV A, PROC_ALIVE
		
		CJNE A, #0x00, check_prio	; check if process is alive
			
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
			
		check_prio:	; check if process has time left
			MOV A, PRIO
			JZ get_prio
			DJNZ PRIO, timer0_intr_fin	; if PRIO = 0 -> change process
				LCALL change_proc
			JMP timer0_intr_fin
			
		get_prio:	; get process priority from process status byte
			
			MOV DPL, TMP_DPL	; get address of the current process
			MOV DPH, TMP_DPH		
			
			INC DPTR	; goto process status byte
			INC DPTR
			
			MOVX A, @DPTR	;get PRIO (first 3 bit)
			ANL A, #0xE0
			RL A
			RL A
			RL A
			
			MOV PRIO, A	

			JMP check_prio
					
		timer0_intr_fin:		
		RETI 
	;;END TIMER_1 INTERRUPT HANDLING
	
	
	;;BEGIN TIMER_1 INTERRUPT HANDLING
	; counts 1s time slices
	;
	timer1_intr:
		MOV TL1, #INIT_TL1				 ; reset timer
		MOV TH1, #INIT_TH1
		DJNZ TIMER1_CNT, timer1_intr_fin ; check if 1s has passed
			INC SECONDS_TIMER			 ; + 1s 
			MOV TIMER1_CNT, #40			 ; restore TIMER1_CNT
		
	timer1_intr_fin:
	RETI
	;END TIMER_1 INTERRUPT HANDLING

END