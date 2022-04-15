    .arch armv8-a

    .include "cfunc.inc.asm"

    .equ MAX_ARGC, 100
    .equ ARGV_AVG_LEN, 0x80000

    .bss
    .p2align 3
gArgvA_Data:
    .space ARGV_AVG_LEN * MAX_ARGC
gArgvA:
    .space 0x08 * MAX_ARGC
gArgc:
    .space 0x08
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         

    .data
    .p2align 3
gArgvA_DataLen:
    .quad gArgvA - gArgvA_Data


    .text
    .p2align 2


    .global _start

    //saved register aliases
    rArgc      .req x19                 //the value of argc
    rArgvW     .req x20                 //start of the argvW pointer array
    rArgvA     .req x21                 //start of the argvA pointer array
    rArgcIdx   .req x22                 //the index of argc
    rArgvANxt  .req x23                 //pointer to the free place in the argvA data block
    rArgvARem  .req x24                 //remaining place in the argvA data block

_start:
    cfunc_prolog _start, RegI=6

    //convert the command line into args
    bl GetCommandLineW                  //lpCmdLine: call https://docs.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-getcommandlinew
    ldr x1, =gArgc                      //pNumArgs: pointer to global argc
    bl CommandLineToArgvW               //https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw 
    cbz x0, _start_err                  //Return value: check if an error occured
    mov rArgvW, x0                      //Return value: save to the local argv (stack local area)
    ldr x9, =gArgc                      //read argc from memory
    ldr rArgc, [x9]

    //init the variables to convert argvW into argvA
    ldr rArgvA, =gArgvA                 //load the address of the argvA pointer array
    ldr rArgvANxt, =gArgvA_Data         //load the start address of the argvA data block
    mov rArgcIdx, #0                    //start at 0
    ldr x9, =gArgvA_DataLen             //read the size of the data block from memory
    ldr rArgvARem, [x9]                 //read
_start_next_argv:
    //try to convert the w-string into an a-string
    mov x0, xzr                         //CodePage: 0 = default ascii code page
    mov x1, xzr                         //dwFlags: no flags
    ldr x2, [rArgvW, rArgcIdx, LSL #3]  //lpWideCharStr: obtain argv at argc index
    mov x3, -1                          //cchWideChar: the size of the string, -1 to indicate to look for the '\0' char
    mov x4, rArgvANxt                   //lpMultiByteStr: write to the start of the free buffer
    mov x5, rArgvARem                   //cbMultiByte: provide the remaining length of the buffer
    mov x6, xzr                         //lpDefaultChar: NULL
    mov x7, xzr                         //lpUsedDefaultChar: NULL
    bl WideCharToMultiByte              //https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-widechartomultibyte
    cbz x0, _start_err                  //Return Value: hcekc if an error occured
    subs rArgvARem, rArgvARem, x0       //Return value: calculate the remaining value
    b.eq _start_err                     //are we at the end of the buffer? Yes --> error

    //use the outcome and move on
    str rArgvANxt, [rArgvA, rArgcIdx, LSL #3] //write the address to the pointer array
    add rArgvANxt, rArgvANxt, x0        //advance the number of bytes writen in the buffer
    add rArgcIdx, rArgcIdx, #1          //idx++
    
    //Next loop?
    cmp rArgcIdx, rArgc                 //how does idx compare to argc?
    b.lt _start_next_argv               //do the next argv if idx was less then argc

    //free the mem of CommandLineToArgvW
    mov x0, rArgvW                      //hMem: the argv memory allocated by CommandLineToArgvW
    bl LocalFree                        //https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-localfree

    //call the main method
    mov x0, rArgc
    mov x1, rArgvA
    bl main                             //call main-method

    //return value
    mov w0, wzr
    b _start_epilog

_start_err:
    mov w0, -1

_start_epilog:
    cfunc_epilog, RegI=6

    .end