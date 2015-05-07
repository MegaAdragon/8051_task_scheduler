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
	CLR SM0
	SETB SM1		
	
	; Baudrate 14400
	ORL ADCON0, #0x80
	ANL PCON, #0x7F
	MOV S0RELL, #0xE6
	;Enable Receive
	SETB REN0
	SETB TI0
	
RET

serial_in:
CLR F0	; clear Flag

JBC RI0, read

RET

read:	
	MOV B, S0BUF
	SETB F0	; set Flag for proc_console
RET

serial_out:
	
	; wait until TI0 = 1
	; only write, when previous write is completed
	wait:
		SETB WDT
		SETB SWDT
		
	JBC TI0, write ; clear TI0
	JMP wait
	
	write:
		MOV S0BUF, B	; write B to serial
		; after successfull write, hardware sets TI0 = 1
RET
END