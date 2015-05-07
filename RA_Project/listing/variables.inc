;-----------------------------------------------
;
; Definitions for global variables
;
;-----------------------------------------------
; Timer (1ms)
; calc: TL0: (65538 - X*2)/256
;		TH0: (65538 - X*2)%256
INIT_TH0			EQU 0xD8	; timer 0 -> 5ms 
INIT_TL0			EQU 0xF2	

INIT_TL1			EQU 0xB2	; timer 1 -> 25ms
INIT_TH1			EQU 0x3C

PROC_ALIVE			EQU 0x31	; activity of process

PROC_TABLE_L		EQU 0x32	; global variable for proc_table position in XDATA
PROC_TABLE_H		EQU 0x33

TMP_DPL				EQU 0x34	; pointer to current position in proc_table
TMP_DPH				EQU 0x35	
PROC_TABLE_INDEX 	EQU 0x36	; index of position in proc_table


PROC_TYPE_ID		EQU 0x37	; process type
; Defines for known processes
ID_A				EQU 0x01	; type A
ID_B 				EQU 0x02	; type B
ID_Z				EQU 0x04	; type Z
ID_CON				EQU 0x00	; type console

TMP_PSW				EQU 0x38	; temporary for psw

TMP_LCALL_L			EQU 0x39	; temporary for return adress of LCALL
TMP_LCALL_H			EQU 0x3A
	
PRIO				EQU 0x3B	; process prio
PID					EQU 0x3C	; proceess ID (PID)

PRC_ADR_L			EQU 0x3D	; start address of a new process
PRC_ADR_H			EQU 0x3E
	
TIMER1_CNT			EQU 0x40	; counter for timer 1
SECONDS_TIMER		EQU 0x41	; counter for seconds
 
TMP_PROC_DATA 		EQU 0x50	; start address for temporary process data in user RAM

PROC_DATA_OFFSET	EQU 13		; 13 Byte offset for process data (DPL,DPH,PSW,B,A,R0...R7)