$NOMOD51
	
#include <Reg517a.inc>
#include "variables.inc"

EXTRN CODE (serial_init)
EXTRN CODE (proc_a)

ORG 0
JMP main

main:

	LCALL serial_init
	
	LCALL proc_a
	
RET 
END