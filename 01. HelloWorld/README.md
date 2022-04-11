# Lesson 1: Hello World

Now that we have our environment setup, it is time to start with our first real world program.  As is tradition, that is off course the classical "Hello Wold!".

The [code](main.asm) functionally consists of:

* Getting the stdout handler
* Writing a predefined string to stdout handler

In order to do this, you need to be able to initialized global data and do basic function calling as described below.

## Data

Since ARM is a RISC architecture, there is a pretty explicit boundary between registers and memory.  In RISC, instructions (with a few dedicated exceptions) can only work with the data in the registries.

### Registers

ARM has 32 64bit registers, of which 30 are "[general-purpose](https://developer.arm.com/documentation/102374/0101/Registers-in-AArch64---general-purpose-registers)" that can be addressed as full 64bit registers by using "x" or 32bit by using "w".  There are also 2 [special](https://developer.arm.com/documentation/102374/0101/Registers-in-AArch64---other-registers), with the x30/lr register somewhere in between general purpose and special.  As if that isn't confusing enough, this is only true when you look at from a hardware perspective.  From a software perspective the general-purpose register are subdivided according to their usage as explained [here](https://docs.microsoft.com/en-us/cpp/build/arm64-windows-abi-conventions?view=msvc-170#integer-registers).

In summary, this is what you need to remember:

* _X0-X7, X29/FP, X30/LR, SP_ have special meaning for [Fuctions](#functions), the tutorials will use them only in that context
* _X9-X15_ are you temporally (scratch) registers, they might be altered upon returning from a function call
* _X19-X28_ are callee-saved registers, their values will be restored upon returning from a function call
* _XZR_ is an abstract register that is always 0 and acts as a "null" device
* _X8, X16-X18_ are used by the OS itself, so better not to use those
* _PC_ is the program counter, while very curial, we don't really need to worry about it.

I like this handy cheat sheet provide by EHN & DIJ Oakley:

 [![ARM64 Register Architecture](https://eclecticlightdotcom.files.wordpress.com/2021/06/armregisterarch.jpg?w=600)](https://eclecticlightdotcom.files.wordpress.com/2021/06/armregisterarch.pdf)

There are also 128bit scalar-floating-point/SIMD-vector registers, but that is for another tutorial.

### Memory

Registers aren't enough, you need memory.  But how do you address that memory in assembly?  Via a register that contains the virtual address off course, but how do you get the address in that registry in the first place?

In the case of the __stack__ memory that is easy, via the _SP_ register, which comes pre-initialized.

Increase the stack size with 16 bytes:

```asm
    sub sp, #0x10
```

Decrease the stack size with 16 bytes:

```asm
    add sp, #0x10
```

Note that in both cases we index by 16 bytes since the ARM processor expects the SP register to by 16 bytes aligned and may fail when it isn't. Also, don't forget that the stack grows down, so the above examples are correct (sub increases and add decreases).

That brings us with the **immediate** parameters.  In the above example `#` denotes an immediate; meaning its value is part of the instruction.  In aarch64, instructions are 32bit and contain the op-code and the references to the used registers.  In general there is some room to spare, so some instructions reserve some bits to put the actual value instead of the id of a register containing the value.  This save cpu-cycles and memory.  Obviously there are some size limits here (we have less the 32 bit), so the range of values you can use are limited.  This limitation is somewhat countered by the fact that immediates consist of a value and a bit-shift, allowing larger numbers that end on binary 0's.

It is also possible to define _aliases_ for immediate values, e.g.:

```asm
.equ NULL, 0 

.text
    mov x0, NULL
```

Allows us to use `NULL` instead of the value `0`.

Finally we come the maybe the most important part, accessing __heap memory__.  Before we can refer to heap, we need to tell the OS we reserved it so it can map the virtual memory of the application to the physical memory of the machine.  The easiest way to do so is by adding a `.data` segment to our source code. A `.data` segment will be part of the executable-file and loading into heap by the OS when your application starts.  While the data in memory itself is type agnostic (it are all bytes), the source files will specify the type of data for the compiler to interpret the literal that is specified.  For example, this is how you define a zero-terminated string:

```asm
    .asciz "My String\n" 
```

The full reference of all definition directives can be found [here](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler?lang=en).

In order to read the data, you need to define a **label** that allows you to find it in memory after the OS loaded it.  This looks like this:

```asm
text:
    .asciz "My String\n" 
```

Getting the address of a label into a register can be done with one of the following instructions:

```asm
    adr x1, text
    adrp x1, text
    ldr x1, =text
```

The `adr x1, text` instruction uses an compiler calculated immediate that is offset against the program counter (the address of memory that is currently being executed).  The advantage is that it uses only 1 instruction, but is limited to labels about 1 MB before or after the current PC value.  This might be an issue for large programs that have big code segments and/or big data segment.

The `adrp x1, text` variant mitigates the 1 MB limit by left shifting the immediate value so that it can reach 4 GB before or after the PC, but as the cost of loosing accuracy since now it can only access labels at the 4K boundary. Be **very careful** with this instruction, because the compiler doesn't care if the label you provide isn't at a 4K boundary, it will simply **round off** and put the address of the nearest 4k boundary in the register.  If you aren't careful, you will read the memory adjacent to label but not the memory at the label itself.

The `ldr x1, =text` can load any address in the 64bit address space, but at the cost of additional instructions since the compiler use a literal pool to store the label's address and load it from there.  In effect, it will convert it in the _equivalent_ of:

```asm
    adr x0, litpool_textaddr
    ldr x0, [x0]
```

Which is more instructions, but also involves reading from memory which is in general slower.  The offset of the literal pool has the same 1 MB offset limitation, but can be easily mitigated by splitting the code in smaller segments since each code segment can be followed by a literal pool.

### Move registers

The easiest is to transfer data between registers, that is simply `mov` like this:

```asm
    mov x1, x0
```

This moves the data from x0 into x1, while keeping the data into x0 (so it is more a copy then a move).  

Obviously the `mov` instruction has support for immediate parameter, usually 16bit.  This means the following is not an issue:

```asm
    mov x0, #26567
```

There is a little caveat though, `mov` isn't known by the CPU; instead the compiler translates it into one of the following instructions `movz` (move zero), `movn` (move not) and `orr` (bitwise or with pattern).  In case of "small" (16 bit or less) positive numbers the compiler will convert `mov` to `movz`, while the same negative number will be converted into a `movn`-instruction with a negated immediate parameter.  The `orr` conversion is when the number can be represented by a repeating pattern of bits.  You don't have to worry to much about it, since the compiler does everything for you.  It is however important to know there are limits, so you understand that when you get a "expected compatible register or logical immediate"-error when you try `mov #0xFFFF1` but not when you try `mov #0x1FFFF` you understand that (while both are more then 16 bit) the former can't be converted to a bit pattern but the latter can.  How to deal with this will be handled in a different lesson.

### Load & Store memory

Once we have a register with the memory address (SP for the stack or any GP register for the heap), we can transfer data between the registers and the memory with the following instructions:

```asm
    ldr x1, [x0]
    ldp x1, x2, [x0]
    str x1, [x0]
    str x1, x2, [x0]
```

The `ldr x1, [x0]` will load the (little-endian) value of memory with the address stored in x0 into register x1, the value of x0 or x1 are not altered.  The `ldp` does the same, but for 2 registers at the same time.  The `str` and `stp` do the opposite, they store the value from x1 into the memory with the address stored in x0.

Note that loading data directly via its label with the `ldr x0, label` instruction isn't supported on Windows.  It has something to do with the executable file format or something, but I'm not sure and I don't care.  It isn't working, so we can't use it and that is all I need to know.

Since indexing is so important, aarch64 has several addressing modes that involve indexing:

* __simple__, `ldr x1, [x0]`: uses the value of x0 as address
* __offset__, `ldr x1, [x0, #4]`: uses the value x0 + 4 as address, x0 keeps its original value.
* __pre-indexed__: `ldr x1, [x0, #4]!`: first add 4 to the value x0 and uses the result as address, x0 is updated
* __post-indexed__: `ldr x1, [x0], #4`: uses x0 as the address and then adds 4 to the value of x0, x0 is updated

Have a look at the official guide here [here](https://developer.arm.com/documentation/102374/0101/Loads-and-stores---addressing).

(_Offset_ addressing variations)

## Functions

(calling conventions, leaf & non-leaf unchained functions)