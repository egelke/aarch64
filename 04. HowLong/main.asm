    .arch armv8-a

    .include "cfunc.inc.asm"


    .equ HIGH_PRIORITY_CLASS, 0x00000080
    .equ BCRYPT_USE_SYSTEM_PREFERRED_RNG, 0x00000002

    .bss
    .p2align 3
procAffinityMask:
    .skip 8
sysAffinityMask:
    .skip 8
wclock_start:
    .skip 8
wclock_end:
    .skip 8
wclock_freq:
    .skip 8
buffer:
    .skip 1024*1024


    .data
    .p2align 3
data:
    .quad 4321
    .quad 5432

const:
    .quad 0x11750BDD65EA37C7

test_empty:
    .asciz "empty"
test_add:
    .asciz "add (sum int)"
test_fadd:
    .asciz "fadd (sum float)"
test_ldr:
    .asciz "ldr (load register)"
test_ldp:
    .asciz "ldp (load register pair)"
test_str:
    .asciz "str (store register)"
test_stp:
    .asciz "stp (store register pair)"
test_const_mov:
    .asciz "constant via move"
test_const_ldr:
    .asciz "constant via ldr"

test_func:
    .asciz "bl/ret (function call)"
test_loop10:
    .asciz "loop 10"
test_branch_j:
    .asciz "b (branch), jump (non predicted)"
test_branch_nj:
    .asciz "b (branch), no jump (predicted)"
test_alloc_mem:
    .asciz "HeapAlloc"
test_init_mem:
    .asciz "zero memory"

timer_msg:
    .asciz "%s took %li.%4.4lims, 0x%lx tick(s)\n"
error_msg:
    .asciz "Process failed\n"
win32_error_msg:
    .asciz "Process failed with error code %lx\n"


    .text
    .p2align 2


/**
 * Perf test memory read/write.
 * 
 * argv[1]: size of the memory to read/write in 1K blocks
 */
    .global main
    cclock_start    .req x19            //the start time in cpu ticks
    cclock_end      .req x20            //the end time in cpu ticks
    heap            .req x21
    var1            .req x22
    var2            .req x23
    var3            .req x24

    .macro timer_start
        ldr x0, =wclock_start           //lpPerformanceCount: address of the wclock_start address
        bl QueryPerformanceCounter      //call https://docs.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter
        mrs cclock_start, PMCCNTR_EL0   //read the clock cycles from the system reg
    .endm

    .macro timer_end
        mrs cclock_end, PMCCNTR_EL0     //read the clock cycles from the system reg
        ldr x0, =wclock_end
        bl QueryPerformanceCounter      //call https://docs.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter
    .endm

    .macro timer_write pName
        ldr x0, =wclock_freq            //lpFrequency: addess of the wclock_feq address
        bl QueryPerformanceFrequency    //call https://docs.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancefrequency

        ldr x9, =wclock_start
        ldr x9, [x9]
        ldr x10, =wclock_end
        ldr x10, [x10]
        sub x9, x10, x9 	            //get the wall clock difference
        ldr x10, =wclock_freq
        ldr x10, [x10]                  //get the wall clock frequency
        mov x11, #0xCA00                //move the lower half of 1 000 000 000 (0xCA00 CA00) into the register
        movk x11, #0x3B9A, LSL #16      //move the upper half of 1 000 000 000 (0x3B9A CA00) into the register
        mul x9, x9, x11
        udiv x9, x9, x10                //get the nano seconds
        mov x11, #0x4240 
        movk x11, #0xF, LSL #16            
        udiv x12, x9, x11               //get the miliseconds
        msub x13, x12, x11, x9          //get the miliseconds remainder
        mov x11, #100
        udiv x13, x13, x11

        sub x10, cclock_end, cclock_start

        ldr x0, =timer_msg              //format
        ldr x1, =\pName                 //test name
        mov x2, x12                     //miliseconds
        mov x3, x13                     //micro-seconds
        sub x4, x10, #1                 //ticks (minus 1)
        bl printf                       //call printf
    .endm

main:
    cfunc_prolog main, RegI=6

    //check if 1 param was provided
    //cmp x0, #2
    //b.ne main_error

    //process arg[1]
    //ldr x0, [x1, #0x08]             //pszSrc: read the arg[1] value
    //bl StrToIntA                    //call: https://docs.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strtointa
    //mov pSize, x0                   //return: keep

    //increase process priority
    bl GetCurrentProcess            //hProcess: call https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
    mov x1, HIGH_PRIORITY_CLASS     //dwPriorityClass: higher prority
    bl SetPriorityClass             //call https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-setpriorityclass
    cbz x0, win32_error             //return: check for error

    //lock the process to a single core
    bl GetCurrentProcess            //hProcess: call https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
    ldr x1, =procAffinityMask       //lpProcessAffinityMask: address in bss
    ldr x2, =sysAffinityMask        //lpSystemAffinityMask: address in bss
    bl GetProcessAffinityMask       //call: https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getprocessaffinitymask
    cbz x0, win32_error             //return: check for error
    ldr x9, =sysAffinityMask        
    ldr x9, [x9]                    ////load the system mask from memory
    ands x9, x9, #0x1               //keep only the last bit
    b.eq main_error                 //check if we have the last bit set
    ldr x10, =procAffinityMask
    str x9, [x10]                   //load the new value
    bl GetCurrentProcess            //hProcess: call https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
    mov x1, x9                      //dwProcessAffinityMask: the new mask
    bl SetProcessAffinityMask       //call https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setprocessaffinitymask
    cbz x0, win32_error             //return: check for error

    //nothing
    timer_start
        //noop
    timer_end
    timer_write test_empty

    //integer add
    mov var1, #19
    mov var2, #21
    timer_start
        add var1, var2, var1
    timer_end
    timer_write test_add

    //floating add
    fmov d17, #3.0
    fmov d18, #2.0E1
    timer_start
        fadd d16, d17, d18
    timer_end
    timer_write test_fadd

    //load a pair of registers
    ldr var1, =data
    timer_start
        ldp var2, var3, [var1]
    timer_end
    timer_write test_ldp

    //store a pair of registers
    ldr var1, =data
    mov var2, #2345
    mov var3, #5432
    timer_start
        stp var2, var3, [var1]
    timer_end
    timer_write test_stp

    //load a variable from memory
    timer_start
        ldr var1, =const
        ldr var1, [var1]
    timer_end
    timer_write test_const_ldr

    //load a contant in 4 parts
    timer_start
        //1175 0BDD 65EA 37C7
        mov var1, #0x37C7
        movk var1, #0x65EA, LSL #0x10
        movk var1, #0x0BDD, LSL #0x20
        movk var1, #0x1175, LSL #0x30
    timer_end
    timer_write test_const_mov

    //call a method
    timer_start
        bl empty_method
    timer_end
    timer_write test_func

    //test branching, train to not branch but branch in the test
    mov var1, #1
    cbz var1, test_branch_j_label
    cbz var1, test_branch_j_label
    cbz var1, test_branch_j_label
    cbz var1, test_branch_j_label
    mov var1, #0
    mov var2, #128
    timer_start
        cbz var1, test_branch_j_label
        add var2, var2, #1
        add var2, var2, #2
        add var2, var2, #3
        add var2, var2, #4
test_branch_j_label:
    timer_end
    timer_write test_branch_j

    //test branching, train to not branch and not branch in the test
    mov var1, #1
    cbz var1, test_branch_nj_label
    cbz var1, test_branch_nj_label
    cbz var1, test_branch_nj_label
    cbz var1, test_branch_nj_label
    mov var1, #1
    mov var2, #128
    timer_start
        cbz var1, test_branch_nj_label
        add var2, var2, #1
        add var2, var2, #2
        add var2, var2, #3
        add var2, var2, #4
test_branch_nj_label:
    timer_end
    timer_write test_branch_nj

    //loop
    mov var1, #10
    cmp var1, #10
    b.ne test_loop10_next
    b.ne test_loop10_next
    b.ne test_loop10_next
    b.ne test_loop10_next
    timer_start
test_loop10_next:
        subs var1, var1, #1
        b.ne test_loop10_next
    timer_end
    timer_write test_loop10

    brk #0xF000
    //allocate dynamic heap
    timer_start
    bl GetProcessHeap               //hHeap: call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    mov x1, xzr                     //dwFlags: null
    mov x2, #(1024*1024)            //dwBytes: number of bytes to allocate
    bl HeapAlloc                    //call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapalloc
    cbz x0, main_error              //return: check if valid address
    mov heap, x0                    //return: move to saved register
    timer_end
    timer_write test_alloc_mem

    //init dynamic heap
    
    add var1, heap, #(1024*1024)
    timer_start
test_init_mem_next:
        sub var1, var1, #10
        stp xzr, xzr, [var1]
        cmp heap, var1
        b.gt test_init_mem_next
    timer_end
    timer_write test_init_mem
    brk #0xF000

    bl GetProcessHeap               //hHeap: call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    mov x1, xzr                     //dwFlags: NULL
    mov x2, heap                    //lpMem: the buffer to free
    bl HeapFree                     //call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapfree    

    //return value
    mov w0, #0
    b main_exit

main_error:
    ldr x0, =error_msg
    bl printf
    mov w0, #-1

win32_error:
    bl GetLastError                 //p1: retrieve the last win32 error
    mov x1, x0
    ldr x0, =win32_error_msg        //pattern: error message with a code 
    bl printf
    mov w0, #-2

main_exit:
    cfunc_epilog RegI=6


empty_method:
    ret
