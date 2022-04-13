    .arch armv8-a

    //https://reviews.llvm.org/rG5b86d130e2baed7221b09087c506f5974fe65f22
    //link: https://reviews.llvm.org/source/llvm-github/browse/main/llvm/test/CodeGen/AArch64/wineh6.mir
    //https://github.com/llvm/llvm-project/issues/54879

    .bss
    .p2align 3
stdOut:
    .space 8
    
    .data
    .p2align 3
pattern:
    .asciz "Meaning Of Life: %c\n"

    .text
    .p2align 2

//some global definitions
.equ STD_OUTPUT_HANDLE, -11

    //entry fucntion "_start"
    .global _start                  //Exporting the "_start" label
    
    a .req x10
    b .req x11
    c .req x9
    
_start:                             //the label of the "_start" function
    .seh_proc _start                //beginning of the function "_start"
    stp fp, lr, [sp, #-0x10]!       //push the framepointer & link register to the stack
    .seh_save_fplr_x 0x10           //tell the compiler you pushed fp and lr to the stack
    mov fp, sp                      //update the frame pointer with the sp value
    .seh_set_fp                     //tell the compiiler you set the frame pointer
    .seh_endprologue                //beginning of the function body

    //get the stdOut in a global variable
    mov x0, STD_OUTPUT_HANDLE       //nStdHandle: STD_OUTPUT_HANDLE = -11
    bl GetStdHandle                 //call https://docs.microsoft.com/en-us/windows/console/getstdhandle
    adr x9, stdOut                  //load the address of stdOut variable (.bss segment)
    str x0, [x9]                    //store the stdOut value in the addess

    //sum 19 & 23
    mov a, #19                      //put 19 in the "a" alias (x10)
    mov b, #23                      //put 23 in the "b" alias (x11)
    add c, a, b                     //put the sum in the "alias" (x9)

    //print it to console
    adr x0, pattern                 //param1: the address of the pattern
    mov x1, c                       //param2: the byte to use in the pattern
    bl printf                       //call our own printf method

                                    //return the value of the previous call, so no need to set w0

    //epilog
    .seh_startepilogue              //end of the function body, start of the unwind
                                    //no sp restore from fp, sp may not be updated after the prologue (at least not for packed)
    ldp fp, lr, [sp], #0x10         //restore the fp and lr from stack
    .seh_save_fplr_x 0x10           //tell the compiler you restored the fp and lr
    .seh_endepilogue                //end of the unwind code
    ret                             //return from the function
    .seh_endfunclet                 //tell the compiler you returned from the function
    .seh_endproc                    //end of the function


    //function printf
    .global printf
    
    p0_pattern .req x19             //define alias for x19, use it for the pattern parameter
    p1_value .req x20               //define alias for x20, use it for the value parameter 
    count .req x21                  //define alias for x21, use it to keep the count

    .equ writen, 0x90               //define the fp-offset of the writen local variable
    .equ buffer, 0x10               //define the fp-offset of the buffer local variable

    .equ printf_savsz, 0x20         //Store 3 RegI, round up to nearest 0x10
    .equ printf_locsz, 0xA0         //Store fp/lr (0x10), 0x80 for buffer + 0x08 for 1 variable ==> 0xA0 rounder to nearest 0x10

printf:
    .seh_proc printf
    stp x19, x20,[sp,#-printf_savsz]!//push x19 & x20 on the stack & reserve savsz space for all Reg that will be stored
    .seh_save_regp_x x19, printf_savsz  
    str x21, [sp, #0x10]            //put x12 on the stack
    .seh_save_reg x21, 0x10
    stp fp, lr, [sp, #-printf_locsz]!//push fp/lr on the stack & allocate space for the local variables
    .seh_save_fplr_x printf_locsz
    mov fp, sp                      //set the fp
    .seh_set_fp
    .seh_endprologue                //beginning of the body of the function

    //save the paramters
    mov p0_pattern, x0              //save the first param in saved reg x19
    mov p1_value, x1                //save the second param in saved reg x20

    //call wsprintfA
    add x0, fp, buffer              //unnamedParam1: caluclate the buffer address as frame pointer offset
    mov x1, p0_pattern              //unnamedParam2: the pattern to use (saved param)
    mov x2, p1_value                //dynamic param0: the value to print (saved param)
    bl wsprintfA                    //call https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-wsprintfa
    mov count, x0                   //save the return value

    //write the buffer to stdOut
    adr x0, stdOut                  //obtain the address of the stdOut global variable
    ldr x0, [x0]                    //hFile: load the value of the stdOut global variable
    add x1, fp, buffer              //lpBuffer: calculate the address of the buffer variable (offset to the fp)
    mov x2, count                   //nNumberOfBytesToWrite: the bytes to write, obtained from the wsprintfA result 
    add x3, fp, writen              //lpNumberOfBytesWritten: calcuate the address of the writen variable (offset to the fp)
    mov x4, xzr                     //lpOverlapped: NULL
    bl WriteFile                    //call https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile

    //return success
    ldr x0, [fp, writen]            //load the date from the written variable into x0 to be returned

    .seh_startepilogue              //end of the body of the function
    ldp fp, lr, [sp], #printf_locsz //pop the fp/lr from the stack & "free" local variable storage
    .seh_save_fplr_x printf_locsz
    ldr x21, [sp, #0x10]            //read x21 from the stack
    .seh_save_reg x21, 0x10
    ldp x19, x20, [sp], #printf_savsz//pop x19 & x20 from the stack & free Reg storage
    .seh_save_regp_x x19, printf_savsz
    .seh_endepilogue                //end of the prologue

    ret                             //return from the function
    .seh_endfunclet                 
    .seh_endproc                    //end of the function