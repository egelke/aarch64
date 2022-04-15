    .arch armv8-a               //specify the target arm version

    .equ STD_OUTPUT_HANDLE, -11 //define a logical name for -11 (see https://docs.microsoft.com/en-us/windows/console/getstdhandle) 
    .equ NULL, 0                //define a logical name for 0

    .data                       //start a data section with initalized data
msg:                            //set a label that refers to the memory adress this place
    .asciz "Hello World!\n"     //initalize some memory, the provided data should be interpreted as string, adding a trailing zero 

    .text                       //start the code section
    .p2align 2                  //align on 2^2 (4) boundary

    .global _start              //the _start label is global and must be exported
_start:                         //the start label, this is the entry point of our programm
    //function prolog
    str lr, [sp, #-0x10]!       //store the link register on the stack (stack pointer must be 16 bytes aligned) 

    //get the handler
    mov x0, STD_OUTPUT_HANDLE   //nStdHandle: the id of the handle to get
    bl GetStdHandle             //call https://docs.microsoft.com/en-us/windows/console/getstdhandle
    mov x9, x0                  //copy the funtion result to a temp register

    //write the string
    mov x0, x9                  //hFile: stdout handler
    adr x1, msg                 //lpBuffer: load the address of the msg data block
    mov x2, #13                 //nNumberOfBytesToWrite: the size of the mesage (counted by hand)
    mov x3, NULL                //lpNumberOfBytesWritten: ignored for the moment, set NULL
    mov x4, NULL                //lpOverlapped: ignored for the moment, set NULL
    bl WriteFile                //call https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile

    //return success
    mov w0, wzr                 //set the function return value with the zero register

    //function epilog
    ldr lr, [sp], #0x10         //restore the link register of the stack
    ret                         //short for "ret lr", i.e. jump to link register, hinting the CPU it's a method return

    .end                        //end of the file

