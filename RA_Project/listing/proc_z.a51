;-----------------------------------------------
;
; Process z module
;		
;-----------------------------------------------

$NOMOD51
NAME proc_z


#include <Reg517a.inc>
#include "variables.inc"

PUBLIC proc_z
EXTRN CODE (fkt_text)
	
proc_z_code SEGMENT CODE
	RSEG proc_z_code
		

proc_z:
	
	LCALL fkt_text	
	
	MOV PROC_ALIVE, #0x00 ; if fkt_text returns -> kill process
	
	; wait for kill
	loop:
		SETB WDT
		SETB SWDT
		
		JMP loop
		
END