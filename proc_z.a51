$NOMOD51
NAME proc_z
; module for process a

#include <Reg517a.inc>
#include "variables.inc"

PUBLIC proc_z
EXTRN CODE (fkt_text)
	
proc_z_code SEGMENT CODE
	RSEG proc_z_code
		

proc_z:
	
	LCALL fkt_text
	
	MOV PROC_ALIVE, #0x00
	
	loop:
		SETB WDT
		SETB SWDT
		
		JMP loop
		
END