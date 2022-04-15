
	/*
     * Creates the prolog of a chained function with packed unwind data 
     * 
     * name: the name of the function (required)
     * RegI: the number of Integer registries (default=0)
     * RegF: the number of floating point registers (default=0). The pdata will have RegF - 1 in the packed unwind date
     * H: 1 to indicate that the Home Registers (x0-x7) must be saved (default=0)
     * alloc: the amound of extra data to allocate (default=0)
     *
     * See: https://docs.microsoft.com/en-us/cpp/build/arm64-exception-handling?view=msvc-160#packed-unwind-data
     */
    .macro cfunc_prolog, name:req, RegI=0, RegF=0, H=0, alloc=0
        //start the proc
        .seh_proc \name

        //save the RegI
        .if \RegI % 2 == 1
            .error "only even Int Regs (RegF % 2 == 0) are supported for now"
        .endif
        .if \RegI > 0
            stp x19, x20, [sp, #-((0x10 * \RegI / 2) + (0x10 * \RegF / 2) + (\H *  0x40))]!
            .seh_save_regp_x x19, (0x10 * \RegI / 2) + (0x10 * \RegF / 2) + (\H *  0x40)
        .endif
        .if \RegI > 2
            stp x21, x22, [sp, #0x10]
            .seh_save_regp x21, 0x10
        .endif
        .if \RegI > 4
            stp x23, x24, [sp, #0x20]
            .seh_save_regp x23, 0x20
        .endif
        .if \RegI > 6
            stp x25, x26, [sp, #0x30]
            .seh_save_regp x25, 0x30
        .endif
        .if \RegI > 8
            stp x27, x28, [sp, #0x40]
            .seh_save_regp x27, 0x40
        .endif

        //Save the RegF
        .if \RegF %2 == 1
            .error "only even FP Regs are supported for now"
        .endif
        .if \RegF >0 && \RegI == 0
            .error "RegF without RegI isn't supported (yet)"
        .endif
        .if \RegF > 0
            stp d8,d9,[sp,#(0x10 * \RegI / 2)]
            .seh_save_fregp d8, (0x10 * \RegI / 2)
        .endif
        .if \RegF > 2
            stp d10,d11,[sp,#(0x10 * \RegI / 2 + 0x10)]
            .seh_save_fregp d10, (0x10 * \RegI / 2 + 0x10)
        .endif

        //Save the home registers
        .if \H <> 0 && \RegI == 0
            .error "H without RegI isn't supported (yet)"
        .endif
        .if \H <> 0
            .error "not supported due to bug in clang (issue #54879)"
            stp x0,x1,[sp,#(0x10 * \RegI * \RegF / 2 + 0x10)]
            .seh_nop
            stp x2,x3,[sp,#(0x10 * \RegI * \RegF / 2 + 0x20)]
            .seh_nop
            stp x4,x5,[sp,#(0x10 * \RegI * \RegF / 2 + 0x30)]
            .seh_nop
            stp x6,x7,[sp,#(0x10 * \RegI * \RegF / 2 + 0x40)]
            .seh_nop
        .endif


        //store the fp/lr pair & allocation local mem
        .if (0x10+\alloc) < 512
            stp fp, lr, [sp, #-(0x10+\alloc)]!
            .seh_save_fplr_x (0x10+\alloc)
        .elseif (0x10+\alloc) == 512
            .error "a #locsz of exaclty 512 not supported with packed unwind data (over-allocate or used unpacked)"
        .elseif (0x10+\alloc) <= 4080
            sub sp,sp,(0x10+\alloc)
            .seh_stackalloc (0x10+\alloc)
            stp fp,lr,[sp]
            .seh_save_fplr 0x0
        .else
            sub sp,sp, #0xFF0
            .seh_stackalloc 0xFF0
            sub sp,sp, (0x10+\alloc-0xFF0)
            .seh_stackalloc (0x10+\alloc-0xFF0)
            stp fp,lr,[sp]
            .seh_save_fplr 0x0
        .endif
        
        //update fp
        mov fp, sp
        .seh_set_fp

        .seh_endprologue

    .endm


    /*
     * Creates the epilog of a chained function with packed unwind data
     * 
     * return: the return instructions (default="ret")
     * RegI..alloc: provide the same value as with prolog creation.
     */
    .macro cfunc_epilog, return=ret, RegI=0, RegF=0, H=0, alloc=0

        .seh_startepilogue

        //restore fp/lr data & free local mem
        .if (0x10+\alloc) < 512
            ldp fp, lr, [sp], (0x10+\alloc)
            .seh_save_fplr_x (0x10+\alloc)
        .elseif (0x10+\alloc) <= 4080
            ldp fp, lr, [sp]
            .seh_save_fplr 0x0
            add sp,sp,(0x10+\alloc)
            .seh_stackalloc (0x10+\alloc)
        .else
             ldp fp, lr, [sp]
            .seh_save_fplr 0x0
            add sp,sp,(0x10+\alloc-0xFF0)
            .seh_stackalloc (0x10+\alloc-0xFF0)
            add sp,sp, 0xFF0
            .seh_stackalloc 0xFF0
        .endif

        //restore the Home registes
        //temp fix for a bug in clang: #54879
        /*
        .if \H <> 0
            stp x6,x7,[sp,#(0x10 * \RegI * \RegF / 2 + 0x40)]
            .seh_nop
            stp x4,x5,[sp,#(0x10 * \RegI * \RegF / 2 + 0x30)]
            .seh_nop
            stp x2,x3,[sp,#(0x10 * \RegI * \RegF / 2 + 0x20)]
            .seh_nop
            stp x0,x1,[sp,#(0x10 * \RegI * \RegF / 2 + 0x10)]
            .seh_nop
        .endif
        */
        
        //restore the save ReF
        .if \RegF > 2
            ldp d10, d11, [sp,#(0x10 * \RegI / 2 + 0x10)]
            .seh_save_fregp d10, (0x10 * \RegI / 2 + 0x10)
        .endif
        .if \RegF > 0
            ldp d8,d9, [sp,#(0x10 * \RegI / 2)]
            .seh_save_fregp d8, (0x10 * \RegI / 2)
        .endif

        //restore the saved RegI
        .if \RegI > 8
            ldp x27, x28, [sp, #0x40]
            .seh_save_regp x27, 0x40
        .endif
        .if \RegI > 6
            ldp x25, x26, [sp, #0x30]
            .seh_save_regp x25, 0x30
        .endif
        .if \RegI > 4
            ldp x23, x24, [sp, #0x20]
            .seh_save_regp x23, 0x20
        .endif
        .if \RegI > 2
            ldp x21, x22, [sp, #0x10]
            .seh_save_regp x21, 0x10
        .endif
        .if \RegI > 0
            ldp x19, x20, [sp], #(0x10 * \RegI / 2) + (0x10 * \RegF / 2) + (\H *  0x40)
            .seh_save_regp_x x19, (0x10 * \RegI / 2) + (0x10 * \RegF / 2) + (\H *  0x40)
        .endif
        
        .seh_endepilogue

        //return from the function
        \return
        .seh_endfunclet

        .seh_endproc

    .endm