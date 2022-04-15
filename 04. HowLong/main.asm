    .arch armv8-a

    .include "cfunc.inc.asm"

    .equ HIGH_PRIORITY_CLASS, 0x00000080


    .bss
    .p2align 3

    .data
    .p2align 3
wmsg:
    .asciz "Write duration: %15Ix (%10Ix / KB)\n"
rmsg:
    .asciz "Read duration:  %15Ix (%10Ix / KB)\n"

    .text
    .p2align 2

    .global main

    buffer .req x19
    bffLen .req x20
    idx    .req x21
    pSize  .req x22

    
main:
    cfunc_prolog main, RegI=4

    cmp x0, #2
    b.ne main_error

    //read first param
    ldr x0, [x1, #0x08]
    bl StrToIntA
    mov pSize, x0
    mov x10, #0x400             //1K
    mul bffLen, pSize, x10

    //init
    bl GetCurrentProcess        //hProcess: call https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
    mov x1, HIGH_PRIORITY_CLASS
    bl SetPriorityClass            //call https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-setpriorityclass
    cbz x0, main_error

    mov x0, bffLen
    bl mem_init
    mov buffer, x0

    mov idx, #5
main_next_write:
    //do benshmark (write)
    mov x0, buffer
    mov x1, bffLen
    bl mem3w
    mov x1, x0

    

    //print result
    ldr x0, =wmsg
    udiv x2, X1, pSize
    //brk #0xF000
    bl printf
    cbz x0, main_error

    sub idx, idx, #1
    cbnz idx, main_next_write

    mov idx, #5
main_next_read:
    //do benshmark (read)
    mov x0, buffer
    mov x1, bffLen
    bl mem3r
    mov x1, x0

    //brk #0xF000

    //print result
    ldr x0, =rmsg
    udiv x2, X1, pSize
    bl printf
    cbz x0, main_error

    sub idx, idx, #1
    cbnz idx, main_next_read

    //cleanup
    mov x0, buffer
    bl mem_clean

    //return value
    mov w0, #0
    b main_exit

main_error:
    mov w0, #-1

main_exit:
    cfunc_epilog RegI=4


.global mem3w
mem3w:
    cfunc_prolog mem3w

    mrs x9, PMCCNTR_EL0
    add x11, x0, x1
mem3w_next: 
    stp xzr, xzr, [x0], #0x10
    cmp x0, x11
    b.ne mem3w_next
    mrs x10, PMCCNTR_EL0

    sub x0, x10, x9                 //return the number of consumed cycles

    cfunc_epilog

.global mem3r
mem3r:
    cfunc_prolog mem3r

    mrs x9, PMCCNTR_EL0
    add x11, x0, x1
mem3r_next: 
    ldp x14, x15, [x0], #0x10
    cmp x0, x11
    b.ne mem3r_next
    mrs x10, PMCCNTR_EL0

    sub x0, x10, x9                 //return the number of consumed cycles

    cfunc_epilog


    .global mem2
mem2:
    cfunc_prolog mem2

    mrs x9, PMCCNTR_EL0
    add x11, x0, x1
mem2_next: 
    strb wzr, [x0], #1
    cmp x0, x11
    b.ne mem2_next
    mrs x10, PMCCNTR_EL0

    sub x0, x10, x9                 //return the number of consumed cycles

    cfunc_epilog




    .global mem1
mem1:
    cfunc_prolog mem1

    mrs x9, PMCCNTR_EL0
    mov x11, #1
mem1_next: 
    subs x1, x1, x11
    b.mi mem1_end
    strb wzr, [x0, x1]
    b mem1_next
mem1_end:
    mrs x10, PMCCNTR_EL0

    sub x0, x10, x9                 //return the number of consumed cycles

    cfunc_epilog




    .global mem_init
mem_init:
    cfunc_prolog mem_init, RegI=2

    mov x19, x0

    bl GetProcessHeap               //hHeap: call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    mov x1, xzr                     //dwFlags: null
    mov x2, x19                     //dwBytes: number of bytes + 1 for the '\0' char at the end
    bl HeapAlloc                    //call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapalloc
                                    //return value: return
    cfunc_epilog RegI=2

    .global mem_clean
mem_clean:
    cfunc_prolog mem_clean, RegI=2

    mov x19, x0

    bl GetProcessHeap               //hHeap: call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    mov x1, xzr                     //dwFlags: NULL
    mov x2, x19                     //lpMem: the buffer to free
    bl HeapFree                     //call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapfree    

    cfunc_epilog, RegI=2





