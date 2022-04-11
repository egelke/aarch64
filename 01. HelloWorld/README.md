# Lesson 1: Hello World

Now that we have our environment setup, it is time to start with our first real world program.  As is tradition, that is off course "Hello Wold!".

The [code](main.asm) is functionally equivalent of the following C program:

```C
#include<Windows.h>

char* msg = "Hello World!\n";

int main() {
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	WriteFile(hOut, msg, 13, NULL, NULL);
	return 0;
}
```

As you can see, it consists of entry-function, initialized global data and function calling.  How to do all this in aarch64 on Windows is described below.

## Data

Since ARM is a RISC architecture, there is a pretty explicit boundary between registers and memory.  In RISC, instructions (with a few dedicated exceptions) can only work with the data in the registries.

### Registers

ARM has 32 registers that are 64 bits long, of these 32, 30 are "[general-purpose](https://developer.arm.com/documentation/102374/0101/Registers-in-AArch64---general-purpose-registers)" that can be addressed as full 64bit registers by using "x" or as 32bit register by using "w".  There are also 2 [special](https://developer.arm.com/documentation/102374/0101/Registers-in-AArch64---other-registers) register, with the x30/lr register somewhere in between general purpose and special.  As if that isn't confusing enough, this is only true when you look at from a hardware perspective.  From a software perspective the general-purpose register are subdivided according to their usage as explained [here](https://docs.microsoft.com/en-us/cpp/build/arm64-windows-abi-conventions?view=msvc-170#integer-registers).

In summary, this is what you need to remember:

* _X0-X7, X29/FP, X30/LR, SP_ have special meaning for [Functions](#functions), the tutorials will only use them in that context
* _X9-X15_ are you temporally (scratch) registers, they might be altered upon returning from a function call
* _X19-X28_ are callee-saved registers, their values will be restored upon returning from a function call
* _XZR_ is an abstract register that is always 0 and acts as a "null" device
* _X8, X16-X18_ are used by the OS itself, so better not to use those (x8 only reserver for Unix, but better stay on the safe side)
* _PC_ is the program counter, while very crucial, we don't need to worry about it much.

I like this handy cheat sheet provide by EHN & DIJ Oakley:

 [![ARM64 Register Architecture](https://eclecticlightdotcom.files.wordpress.com/2021/06/armregisterarch.jpg?w=600)](https://eclecticlightdotcom.files.wordpress.com/2021/06/armregisterarch.pdf)

There are also 128bit scalar-floating-point/SIMD-vector registers, but that is for another tutorial.

### Memory

Registers alone aren't enough, you need memory.  But how do you address that memory in assembly?  Via a register that contains the virtual address off course, but how do you get the address in that registry in the first place?

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

That brings us with the **immediate** parameters.  In the above example `#` denotes an immediate; meaning its value is part of the instruction.  In aarch64, instructions are 32bit and contain the op-code and the references to the used registers.  In general there are some bits to spare, so some instructions reserve some bits to put the actual value in, instead of referring the register containing the value.  This saves cpu-cycles and memory.  Obviously there are some size limits here (we have less then 32 bit), so the range of values you can use is always limited.  This limitation is often somewhat countered by the fact that immediates may by bit-shifted or a pattern of bits.  This allowing larger numbers but not any possible values, but what is possible tends to be the values often required in low level programming.

It is also possible to define _aliases_ for immediate values, e.g.:

```asm
.equ NULL, 0 

.text
    mov x0, NULL
```

In the above example `NULL` is the alias for value `0`.

Finally we come the maybe the most important part, accessing __heap memory__.  Before we can refer to heap, we need to tell the OS we need it so it can map the virtual memory of the application to the physical memory of the machine.  The easiest way to do so is by adding a `.data` segment to our source code. A `.data` segment will be part of the executable-file and loading into heap by the OS when it start your application.  While the data in memory itself is type agnostic (it's all one big array of bytes), in the source files will need to specify the type.  This is needed for the compiler to interpret the literal value in your source file.  For example, this is how you define a zero-terminated string:

```asm
    .asciz "My String\n" 
```

The full reference of all definition directives can be found [here](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler?lang=en).

In order to read the data, you need to define a **label** that allows you to find it in memory after the OS loaded it.  This looks like this:

```asm
text:
    .asciz "My String\n" 
```

Getting the address of a label into a register can be done with one of the following ways:

```asm
    adr x1, text        //get the address for label "text"
    adrp x1, text       //get the 4K pages address for label "text"
    ldr x1, =text       //get the address for label "text" via a literal pool.
```

The `adr x1, text` instruction uses an compiler calculated immediate that is offset against the program counter (the address of memory that is currently being executed).  The advantage is that it uses only 1 instruction, but is limited to labels about 1 MB before or after the current PC value.  This might be an issue for large programs that have big code segments and/or big data segment.

The `adrp x1, text` variant mitigates the 1 MB limit by left shifting the immediate value 12 bits so that it can reach 4 GB before or after the PC, but as the cost of loosing accuracy since now it can only access labels at the 4K boundary. Be **very careful** with this instruction, because the compiler doesn't care if the label you provide isn't at a 4K boundary or not, it will simply **round off** and put the address of the 4k boundary in the register.  If you aren't careful, you will read wrong portion of memory.

The `ldr x1, =text` can load any address in the 64-bit address space, but at the cost of additional instructions since the compiler use a literal pool to store the label's address and load it from there.  In effect, it will execute the _equivalent_ of:

```asm
    adr x0, litpool_textaddr
    ldr x0, [x0]
```

Which is not only more instructions, it also involves reading from memory which is in general slower.  The offset of the literal pool has the same 1 MB offset limitation, but can be easily mitigated by splitting the code in smaller segments since each code segment can be followed by a literal pool, which tend to be small since they only contain addresses, no actual data.

### Move registers

Transferring data between registers is simple, use the `mov`-instruction.  Like this:

```asm
    mov x1, x0
```

This moves the data from x0 into x1, while keeping the data into x0 (so it is more a copy then a move).  

Obviously the `mov` instruction has support for immediate parameter, usually 16bit long.  This means the following is not an issue:

```asm
    mov x0, #26567
```

There is a big caveat though, `mov` isn't known by the CPU; instead the compiler translates it into one of the following instructions `movz` (move zero), `movn` (move not) and `orr` (bitwise or with pattern).  In case of "small" (16 bit or less) positive numbers the compiler will convert `mov` to `movz`, while the same negative number will be converted into a `movn`-instruction with a negated immediate parameter.  The `orr` conversion is used when the number can be represented by a repeating pattern of bits.  You don't have to worry about the inner working to much, since the compiler does everything for you.  It is however important to know there are limits, so you understand tha you can get a "expected compatible register or logical immediate"-error when you try `mov #0xFFFF1` but not when you try `mov #0x1FFFF`. The former can't be converted to a bit pattern but the latter can.  How to deal with this will be explained in a future lesson.

### Load & Store memory

Once we have a register with the memory address (SP for the stack or any GP register for the heap), we can transfer data between the registers and the memory with the following instructions:

```asm
    ldr x1, [x0]
    ldp x1, x2, [x0]
    str x1, [x0]
    str x1, x2, [x0]
```

The `ldr x1, [x0]` will load the (little-endian) value of memory with the address stored in x0 into register x1, the value of x0 or x1 are not altered.  The `ldp` does the same, but for 2 registers at the same time.  The `str` and `stp` do the opposite, they store the value from x1 (and x2) into the memory starting with the address stored in x0.

Note that loading data directly via its label with the (often cited) `ldr x0, label` instruction isn't supported on Windows.  It has something to do with the executable file format or something, but I'm not sure and I don't care.  It isn't working, so we can't use it and that is all I need to know.

Since we often need to index a pointer (i.e. updates it's value when using), aarch64 has several addressing modes:

* __simple__, `ldr x1, [x0]`: uses the value of x0 as address (as explained above)
* __offset__, `ldr x1, [x0, #4]`: uses the value x0 + 4 as address, x0 keeps its original value.
* __pre-indexed__: `ldr x1, [x0, #4]!`: first add 4 to the value x0 and uses the result as address, x0 remains altered
* __post-indexed__: `ldr x1, [x0], #4`: uses x0 as the address and then adds 4 to the value of x0, x0 remains altered

Have a look at the official guide here [here](https://developer.arm.com/documentation/102374/0101/Loads-and-stores---addressing).

While aarch64 has (in contradiction to 32bit ARM) no push/pop instructions to manipulate the stack, you must simply use the equivalent vanilla instructions instead:

```asm
    stp x0, x1, [sp, #-0x10]!       //push x0 & x1 to the stack
    ldp x0, x1, [sp], #0x10         //pop x0 & x1 from the stack
```

## Unchained Functions

On Windows an application is a function that is called by the OS.  The application's entry function doesn't have any parameters and as long as you don't call any functions yourself (i.e. your entry function is a _leaf-function_) you simply call `ret` at the end to return to the OS.  Setting the `w0` registers set the return code of the program, setting it "0" (with the aide of the `wzr` register) tells the outside world that your program finished successfully.

Calling functions requires some extra work.  Calling a function is done with the `bl label` instruction which is a mnemonic for "branch link".  It will not only jump to that code, it will also **update** the `lr` register with the return address of the function (the code right after the `bl label` instruction).  The `ret` instruction will then "branch" back to the `lr` register.

Since all methods use the same `lr` register and there is nothing in the hardware or the OS that keeps track of it, it is up to you to safe-keep its value before you use the `bl` instruction.  If you don't, then you probably end up in an endless loop since you will return to the wrong address. The convention is that you put it on the stack when you enter your function and restore is from stack before you leave your function:

```asm
entry:
    str lr, [sp, #-0x10]!
    //...
    ldr lr, [sp], #0x10
    ret
```

Using the stack, and not the heap, allow you to nest calls without any worries (at least until you run out of stack space).

That just leaves us with the question on how to provide the parameters to the function call... The `bl`-instruction only has 1 fixed parameters: the label.  How do you provide the other parameters?  This [calling conventions](https://docs.microsoft.com/en-us/cpp/build/arm64-windows-abi-conventions?view=msvc-170#parameter-passing) is agreed up, and can be quite complicated. For now you simply need to know that registers `x0` to `x7` are your parameters.  A function with 1 parameter uses `x0` only, one with 2 parameters uses `x0` and `x1`, ...

If for example, if you look at the  [`WriteFile`](https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile) documentation you see that it has 5 parameters, so we need to set `x0` to `x4` as so:

```asm
    mov x0, x9
    adr x1, msg
    mov x2, #13
    mov x3, NULL
    mov x4, NULL
    bl WriteFile
```

Once in a function, which registers may you use?  You may use the `x0`-`x7` registers in any why you like, but since they are used for function parameters I tend to only use them for that purpose (even the "spare").  That make the code a little more readable, and we can use all the readability we can get when it comes to assembly.

Registers `x9`-`x15` are unsaved scratch registers, free to use without any constraints but they may be altered when returning from a function.  You can't not assume that any of the registers in this range will remain the same after you return from a function (i.e. after a `bl` instruction).

Registers `x19`-`x28` are persistent, but you are supposed to safeguard the current value before using them.  This is not covered in this lesson, for that you need to wait until the next lesson where I explain this together with chained functions.

## Conclusion

There was a lot to cover, even for this simple program, but with this you should be able to fully understand what is going on.  Like with any language, there is a minimal set of knowledge that you need to master in order use it beyond simply repeating mindlessly.  Now that you have the basis, we can build on top of that.
