    .arch armv8-a

    //https://reviews.llvm.org/rG5b86d130e2baed7221b09087c506f5974fe65f22
    //link: https://reviews.llvm.org/source/llvm-github/browse/main/llvm/test/CodeGen/AArch64/wineh6.mir
    //https://github.com/llvm/llvm-project/issues/54879

    .bss
stdOut:
    .space 8
    
    .data
pattern:
    .asciz "Meaning Of Life: %c\n"

    .text
    .p2align 2

.equ STD_OUTPUT_HANDLE, -11

a .req x10
b .req x11
c .req x9

    .global _start                  //Exporting the "_start" label
_start:                             //the label of the "_start" function
    .seh_proc _start                //beginning of the function "_start"
    stp fp, lr, [sp, #-0x10]!       //push the framepointer & link register to the stack
    .seh_save_fplr_x 0x10           //tell the compiler you pushed fp and lr to the stack
    mov fp, sp                      //update the frame pointer with the sp value
    .seh_set_fp                     //tell the compiiler you set the frame pointer
    .seh_endprologue                //beginning of the function body

    mov x0, STD_OUTPUT_HANDLE
    bl GetStdHandle
    adr x9, stdOut
    str x0, [x9]

    mov a, #19
    mov b, #23
    add c, a, b

    mov x0, c
    bl printc

    //return success
    mov w0, wzr

    //epilog
    .seh_startepilogue              //end of the function body, start of the unwind
                                    //no sp restore from fp, sp may not be updated after the prologue (at least not for packed)
    ldp fp, lr, [sp], #0x10         //restore the fp and lr from stack
    .seh_save_fplr_x 0x10           //tell the compiler you restored the fp and lr
    .seh_endepilogue                //end of the unwind code
    ret                             //return from the function
    .seh_endfunclet                 //tell the compiler you returned from the function
    .seh_endproc                    //end of the function


value .req x19
count .req x20
result .req x21

.equ writen, 0x90
.equ buffer, 0x10

    .global printc
printc:
    .seh_proc printc
    stp x19, x20,[sp,#-0x20]!
    .seh_save_regp_x x19, 0x20
    str x21, [sp, #0x10]
    .seh_save_reg x21, 0x10
    stp fp, lr, [sp, #-0xA0]!       //allocate 0x10 for the fp/lr + 0x80 for the buffer + 0x08 for the "writen" -> 0x98 (= 0xA0 rounded)
    .seh_save_fplr_x 0xA0
    mov fp, sp
    .seh_set_fp
    .seh_endprologue

    mov value, x0

    add x0, fp, buffer
    adr x1, pattern
    mov x2, value
    bl wsprintfA
    mov count, x0

    adr x0, stdOut
    ldr x0, [x0]
    add x1, fp, buffer
    mov x2, count
    add x3, fp, writen
    mov x4, xzr
    bl WriteFile

    //return success
    mov w0, wzr

    .seh_startepilogue
    ldp fp, lr, [sp], #0xA0
    .seh_save_fplr_x 0xA0
    ldr x21, [sp, #0x10]
    .seh_save_reg x21, 0x10
    ldp x19, x20, [sp], #0x20
    .seh_save_regp_x x19, 0x20
    .seh_endepilogue

    ret
    .seh_endfunclet
    .seh_endproc