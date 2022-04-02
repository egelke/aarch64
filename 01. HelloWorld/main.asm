	.arch armv8-a

.equ STD_OUTPUT_HANDLE, -11

	.data
msg:
	.asciz "Hello World!\n"

	.text

	.global _start
_start:
	//prolog
	str lr, [sp, #-0x10]!		//store the link register (stack pointer must be 16 bytes aligned) 

	//get the handler
	mov x0, STD_OUTPUT_HANDLE	//nStdHandle: the id of the handle to get
	bl GetStdHandle				//https://docs.microsoft.com/en-us/windows/console/getstdhandle
	mov x9, x0					//copy the result to a temp register

	//write the string
	mov x0, x9					//hFile: stdout handler
	adr x1, msg					//lpBuffer: load the address of the msg data block
	mov x2, #13					//nNumberOfBytesToWrite: the size of the mesage (counted by hand)
	mov x3, #0					//lpNumberOfBytesWritten: ignored for the moment, set NULL
	mov x4, #0					//lpOverlapped: ignored for the moment, set NULL
	bl WriteFile				//call the WriteFile method in Kernel32.dll

	//return success
	mov w0, #0x0

	//epilog
	ldr lr, [sp], #0x10
	ret							//short for "ret lr", i.e. jump to link register, hinting the CPU it's a method return


	.end