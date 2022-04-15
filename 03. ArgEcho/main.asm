    .arch armv8-a

    .include "cfunc.inc.asm"

    .bss
    .p2align 3

    .data
    .p2align 3
prog_msg:
    .asciz "Program=%s\n"
arg_msg:
    .asciz "Argument=%s\n"

    .text
    .p2align 2

    .global main

    argc    .req x19
    argv    .req x20

main:
    cfunc_prolog main, RegI=2, H=1

    //store the params
    mov argc, x0
    mov argv, x1

    //print the program name
    adr x0, prog_msg
    ldr x1, [argv], #0x08
    bl printstr

    //loop over the remaining args
next_arg:
    sub argc, argc, #1
    cbz argc, finished

    adr x0, arg_msg
    ldr x1, [argv], #0x08
    bl printstr

    b next_arg

finished:
    //return value
    mov w0, #0

    cfunc_epilog RegI=2, H=1
