    .arch armv8-a       //hint which version of the CPU we are targeting

    .text               //start of the code block
    .p2align 2          //align the code on 2^2 (i.e. 4) bytes

    .global _start      //expose the sum-method
_start:                 //the start of the sum-method


    //sum 2 constants
    mov x10, #19        //put 19 in register 10
    mov x11, #23        //put 23 in register 11
    add x9, x10, x11    //put the sum of 19 and 23 in register 9

    mov w0, wzr         //set the function return value with the zero register

    ret                 //return from the sum-method to the caller

    .end                //end of the file
    