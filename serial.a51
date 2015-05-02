$NOMOD51
NAME serial
; module for serial i/o

#include <Reg517a.inc>

PUBLIC serial_init ; init serial i/o
PUBLIC serial_in ; reads from serial port
PUBLIC serial_out ; writes to serial port
	
serial_code SEGMENT CODE
	RSEG serial_code
	
serial_init:
	
	; Set SerialMode 1
	ORL S0CON,#0x50	
	;Serial Mode 1 in S1CON
	ORL S1CON, #0x80
	
	; Baudrate 9600
	ORL ADCON0, #0x80
	ANL PCON, #0x7F
	;Enable Receive
	SETB REN0
	SETB TI0
	
RET

serial_in:
CLR F0

JBC RI0, read

RET

read:	
	MOV B, S0BUF
	SETB F0
	
RET

serial_out:
	
	; wait until TI0 = 1
	wait:
		SETB WDT
		SETB SWDT
		
	JBC TI0, write
	JMP wait
	
	write:
		MOV S0BUF, B
RET
END