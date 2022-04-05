    .arch armv8-a

    .text
    .p2align 2

    //entry point (see linker)
    .global sum
sum:
    //sum 2 constants
    mov x10, #1
    mov x11, #1
    add x9, x10, x11

    //return success (0)
    mov w0, wzr

    ret

    .end