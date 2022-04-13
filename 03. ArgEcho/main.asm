    .arch armv8-a

    .include "cfunc.inc.asm"

    .bss
    .p2align 3
prog_umsg:
    .skip (prog_umsg_size - prog_msg)*2
arg_umsg:
    .skip (arg_umsg_size - arg_msg)*2 
bss_end:

    .data
    .p2align 3
prog_msg:
    .asciz "Program=%s\n"
prog_msg_size:
    .dword . - prog_msg
prog_umsg_size:
    .dword arg_umsg - prog_umsg
arg_msg:
    .asciz "Argüment=%s\n"
arg_msg_size:
    .dword . - arg_msg
arg_umsg_size:
    .dword bss_end - arg_umsg


    .text
    .p2align 2

    .global _start
    
    .equ argc_offset, 0x10
    .equ argv_offset, 0x18
_start:
    cfunc_prolog _start, RegI=0, alloc=0x10

    mov x0, #65001                       //CodePage:
    mov x1, xzr                         //dwFlags: NULL
    adr x2, prog_msg                    //lpMultiByteStr   
    adr x3, prog_msg_size
    ldr x3, [x3]
    adr x4, prog_umsg
    adr x5, prog_umsg_size
    ldr x5, [x5]
    bl MultiByteToWideChar              //call: https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar

    mov x0, #65001                       //CodePage:
    mov x1, xzr                         //dwFlags: NULL
    adr x2, arg_msg                     //lpMultiByteStr   
    adr x3, arg_msg_size
    ldr x3, [x3]
    adr x4, arg_umsg
    adr x5, arg_umsg_size
    ldr x5, [x5]
    bl MultiByteToWideChar              //call: https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar

    //get the command line
    bl GetCommandLineW                  //https://docs.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-getcommandlinew
                                        //return value: directly used in next step

    //convert the command line into args
                                        //lpCmdLine: command line address (already set)
    add x1, fp, argc_offset             //pNumArgs: pointer to local argc (stack local area)
    bl CommandLineToArgvW               //https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw 
    str x0, [fp, argv_offset]           //Return value: save to the local argv (stack local area)
    
    //call the main method
    ldp x0, x1, [fp, argc_offset]       //load argc & argv from local (stack) storage
    bl main                             //call main-method

    //free the mem of CommandLineToArgvW
    ldr x0, [fp, argv_offset]           //hMem: the argv memory allocated by CommandLineToArgvW
    bl LocalFree                        //https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-localfree

    //return value
    mov w0, wzr

    cfunc_epilog, RegI=0, alloc=0x10



    .global main

    argc    .req x19
    argv    .req x20

main:
    cfunc_prolog main, RegI=2

    //store the params
    mov argc, x0
    mov argv, x1

    //print the program name
    adr x0, prog_umsg
    ldr x1, [argv], #0x08
    bl printstr

    //loop over the remaining args
next_arg:
    sub argc, argc, #1
    cbz argc, finished

    adr x0, arg_umsg
    ldr x1, [argv], #0x08
    bl printstr

    b next_arg

finished:
    //return value
    mov w0, #0

    cfunc_epilog RegI=2