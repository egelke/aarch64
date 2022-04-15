    .arch armv8-a

    .include "cfunc.inc.asm"
    
    .equ STD_OUTPUT_HANDLE, -11

    .global printf

    .equ buffer, 0x20             //define the fp-offset for the start of the buffer
    .equ writen, 0x10             //define the fp-offset of the writen local variable

printf:
    cfunc_prolog printf, RegI=0, alloc=0x410

    //shift the parameters up, add the buffer & call
    mov x7, x6
    mov x6, x5
    mov x5, x4
    mov x4, x3
    mov x3, x2
    mov x2, x1
    mov x1, x0
    add x0, fp, buffer
    bl wsprintfA                    //call https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-wsprintfa
    mov x2, x0                      //Return value: save the generates string len a byte len

    //write the buffer to stdOut
    mov x0, STD_OUTPUT_HANDLE       //nStdHandle: STD_OUTPUT_HANDLE = -11
    bl GetStdHandle                 //hFile: call https://docs.microsoft.com/en-us/windows/console/getstdhandle
    add x1, fp, buffer              //lpBuffer: calculate the address of the buffer variable (offset to the fp)
                                    //nNumberOfBytesToWrite: return value of wsprintfA
    add x3, fp, writen              //lpNumberOfBytesWritten: calcuate the address of the writen variable (offset to the fp)
    mov x4, xzr                     //lpOverlapped: NULL
    bl WriteFile                    //call https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile
    cbz x0, printf_exit

    //return success
    ldr x0, [fp, writen]            //load the date from the written variable into x0 to be returned

printf_exit:
    cfunc_epilog RegI=0, alloc=0x410

    .end