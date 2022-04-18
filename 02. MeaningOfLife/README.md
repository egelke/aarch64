# Lesson 2: Meaning of Life

The assembly [code](main.asm) of this lesson is functionally equivalent to the following C program:

```C
#include<Windows.h>

int myprintf(char* p, char a);

HANDLE stdOut;
char* pattern = "Meaning Of Life: %c\n";

int main() {
    stdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    char a = 19 + 23;

    return myprintf(pattern, a);
}

int myprintf(char* p, char input) {
    int count;
    DWORD writen;
    char buffer[128];

    count = wsprintfA(buffer, p, input);

    WriteFile(stdOut, buffer, count, &writen, NULL);

    return writen;
}
```

Yes, I'm very well aware that the above code will not win any prices (maybe with the exception of worst code).  The goal here isn't to write perfect C, it is to learn how to write aarch64 assembly.  That being said, what does it do?  Well it add 19 and 23, which give you 42 (the meaning of life if I recall correctly) and prints it out to the screen.

Why do we do this? Mainly to extend our knowledge with regards to functions.  We add the concept of chained function and learn what are saved registers.  Additionally we learn a few additional basic concepts of assembly source files, and dive a little deeper into memory.

## Source files

In the previous lessons, we went over the basic concepts of assembly programming: some instructions like `add`, how to use registers, how to use data, ...  We didn't however explain what an assembly source file is constructed of, so lets do that now.

We generally start with the `.arch` directive explained [here](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/AArch64-Target-selection-directives).  It tells the compiler which version of arm we are targeting so it knows which instructions to expect.  At this time we will simply specify `armv8-a` meaning ARMv8, A(pplicaton) profile.  You should end the assembly file with `.end`, but that is optional; just good practice.

As indicated in the previous lesson, you can define an alias for constants with the `.equ` directive.  You can also define an registers alias with the `.req` directive, for example:

```asm
    .equ NULL, 0        //defines NULl as alias for #0
    param1 .req x0      //defines myReg as alias

    mov param1, NULL    //use both aliases, puts #0 into x0
```

Why they have totally different syntaxes beats me, but you will get used to it quite quickly.  While you can have multiple aliases for the same, you can't redefine alias within the same source file.  You will need to split up your sources in different files, use different names or simply don't use aliases.

## Memory

In the previous lessons we touched on the usage of memory, but didn't really explain it properly.  So lets do that now.

Basically all modern computers use the same memory for both data and code since [Von Neumann](https://en.wikipedia.org/wiki/Von_Neumann_architecture) described it as being the best option.  However, that doesn't mean we simply throw everything randomly together (as Von Neumman suggested), instead we organize it nicely in different section like this:

[![Virtual Memory Layout](https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Program_memory_layout.pdf/page1-94px-Program_memory_layout.pdf.jpg)](https://en.wikipedia.org/wiki/Data_segment)

This represents the most common virtual memory layout as seen by the application (bottom = lowest address). Its the OS's job to map this on physical memory in ways that are way beyond the scope of this tutorial.

The __text__, __data__ and __bss__ section are part of the executable and therefore defined by the source files so the compiler knows how to generate them (how to define those is described [here](#sections)).  When the OS start your application, it loads these sections accordingly.  The _text_ and _data_ section will be initialized with actual values, the former with your code and the later with predefined data.  The _bss_ section is not initialized and will either contain all `0`'s or "garbage". The _text_ section is ready only, writing to it should be blocked by the OS.  The _data_ and _bss_ are read/write.  Note that writes to the _data_ section only update the memory, not the executable, so the next time your start your application the memory will be back at the original values.  Also note that _text_ and _data_ segments are actually part of you executable file, so do not put large arrays in your _data_ segment since that will create large executable that take a long time to load; use _bss_, _heap_ or _stack_ instead.

The __Heap__ and __stack__ are different, they are dynamic memory: you need to be initialize and managed them via your code.  The stack is described [here](#stack), while for the heap you have to be a little patient and wait for the next lesson.  Note that _bss_, _data_ and even _text_ segments can also be refereed to as _heap_ (one way of allocating dynamic heap is by extend the _bss_ section via code).  Sorry if it gets confusing at times, I'll do my best to use _heap_ solely for the dynamic allocated memory only.

CPUs work best when they can access memory aligned on their natural boundaries (some even even require it).  Since aarch64 instructions are 32 bit in length and operate on 64 bit data, it is advised to align the _text_ section on 32 bit boundaries and _data_ and _bss_ sections on 64 bit boundaries.

Don't forget that, in the end, it is all one continuous amount of virtual memory: _there are __no real boundaries__ between segments or labeled blocks_.  Sure, the OS should prevent your from reading unallocated memory or writing to read-only memory, but that is it.  You can as easily read the text-segment as you can read the data-segment.  You can read a block of the data you think is an integer, but was actually initialized as part of a string or a piece of code.  There are __no types__ in assembly, there is just continuously memory for which you are responsible to keep track of what is where (with a little help of the compiler).

### Fixed memory

You specify a __text__, __data__ or __bss__ section in your code file with either the `.section` or one of handy aliases as described [here](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/Section-directives).

The `.text` section is where you put your code.  As indicated before, you need to define a function with a label that your indicate as your entry point in the linker.

The `.data` section is where you define (labeled) blocks of memory that have pre-defined values. You can define this values as a [string](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/String-definition-directives), [integer](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/Data-definition-directives), [float](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/Floating-point-data-definition-directives) values or a sequence of [bytes](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/Space-filling-directives) values.  For example:  

```asm
message:
    .asciz "My message to you\n"
int64:
    .quad -1386916717
float_pi:
    .float 3.14159265359
array:
    .space 512 
```

The final section is `.bss`, where you define (labeled) blocks of memory that doe not have pre-defined values, i.e. you have a series of `.space` directive.

Aligning the section on the proper boundary can be done with the `.p2align` directive described [here](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler/Alignment-directives) and described a power of 2 alignment.  The `.text` segment should be `.p2align 2` or 2² = 4 while `.data` and `.bss` should be `p2align 3` or 2³ = 8.

### Stack Memory

As explained in the [above](#memory) section, the _Stack_ is dynamic memory that you need to managed for the most part.  It resist on the top part of the applications memory space, so increasing it means reducing the pointer to it.  In the previous lesson we already learned that it is controlled by the `sp` register which must be __16 bytes aligned__.  You also learned how to push and pop something on the stack, or increase/decrease its size:  

```asm
    stp x0, x1, [sp, #-0x10]!       //push x0 & x1 to the stack
    sub sp, #400                    //increase the stack with 1K
    ...
    add sp, #400                    //decrease the stack with 1K 
    ldp x0, x1, [sp], #0x10         //pop x0 & x1 from the stack
```

That is basically all you need to know about the anatomy and manipulation of the stack, that doesn't however explain why there is a stack in the first place.  Why is it so important and what can it is used for?

The first reason why Stack is so important is __convenience__.  Changing the size can be done with a single hardware instruction, you will see later on that this is't the case for _heap_ manipulations.  Sure there is the _bss_ segment, but that can't grow as easily as a stack can.  Historically stack size where very limited, but not so much any more, but there is still a (size) limit to stacks.

Even more relevant then convenience is the fact that it's perfect to serve as __local storage__, compared to the _global_ storage of _data_, _bss_ and _heap_.  Local refers to the fact that it local to a function call: each function will have its own separate storage even when you call the same function recursively.  There is no magic here, each function is supposed to put its data on top of whatever is already on the stack.  At the beginning of a function it will simply adds its "stuff" onto the stack, that stuff is called a "__frame__".  More on function calls in the next section.

## Functions

In the intro lesson we learned about __leaf function__, those are function that do not call any other function.  In the previous lesson we learned about __unchained non-leaf function__, those are functions that call other functions but don't take any action to properly record the chain of functions: they simply throw their stuff on the stack without indication of its frame boundary.  You rely entirely on the code have popped everything back from the stack upon completion.  In this lesson we focus on __Chained functions__, these functions follow conventions.  These specify when and how to push their stuff on the stack and the usage of the `fp` register (alias for `x30`) to mark the boundary of their frame.  While it is still _mostly_ the code itself that must ensure all data is popped from the stack upon completion, it is less likely to screw it up when following a convention.  It does also allow debuggers to interpret the stack and allows Windows OS to [Frame Base Exception Handling](https://docs.microsoft.com/en-us/windows/win32/debug/frame-based-exception-handling).

On aarch64 your __stack frame__ looks as follows, you are function B which is called by function A and calls function C:

[![ARM64 Stack Frame](https://docs.microsoft.com/en-us/cpp/build/media/arm64-exception-handling-stack-frame.png?view=msvc-160)](https://docs.microsoft.com/en-us/cpp/build/arm64-exception-handling?view=msvc-160#arm64-stack-frame-layout)

In order to manage this a function execution is divided in the following phase, with the following stack manipulations:

* __prolog(ue)__: create the "fixed" part of the stack frame, which consist of 3 sub-steps
  * save non volatile registers, which consist of 3 sub-steps
    * allocation all register memory & save the integer registers
    * save floating point registers
    * save home (incoming parameter) registers
  * allocate remaining storage including local (stack) area and push `fp`/`lr` register pair to it
  * mark the boundary of the stack frame by copying `sp` register to the `fp` register
* __function body__: the actual function code, which may include:
  * dynamic extension of the stack, similar to using [_alloca](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/alloca) in C
  * parameters 8 and beyond for outgoing function (function C in the above diagram) call
* __epilog(ue)__: freeing the stack frame & restoring registers in the 3 sub-steps
  * freeing the dynamic allocated stack by copying the `fp` registers back to the `sp` register
  * free the local stack and restoring the `fp`/`lr` register pair by popping them from the stack
  * restore the non-volatile registers, which consist of 2 sub-steps
    * restore the floating point registers
    * restore the integer registers and free all of the register memory

A few notes:

* You don't have to put saved registers on the stack unless you actually use them
* Home registers (`x0` to `x7`) do not need to be restored, you simply save them to be referenced in the function code
* The local area in the prolog is optional (i.e. size=0), but saving the `fp`/`lr` pair isn't[^1]
* dynamic extension of the stack is purely optional
* restoring `sp` from `fp` is only required if you updated the `sp` after the prolog, i.e. dynamically extend the stack

[^1]: the size allocated in this step is therefor at least 0x10 bytes.

In the [source](main.asm) file you will find 2 examples.  The `_start` function is the most basic example possible, it saves no registers nor doesn't have any local area; it simply saves the `fp`/`lr` pair in the prolog and restores it in the epilog.  The `_printf` functions it a little more complicated, it uses 3 integer registers (`x19` to `x21`) and needs 0x88 of local area; because of the 0x10 (16) bytes alignment of the `sp` it allocates 0x20 bytes for the registers.It also allocations 0x90 for the local area, plus an additional 0x10 for the `fp`/`lr` pair, so 0xA0 in total.

There are off course endless variants: different order, leaving out optional parts, ... Some variations are still confirm to "chained functions", but some wont.  Since I'm no expert myself and I assume you aren't either, we needed a way to _formalize_ and _verify_ otherwise we might think it is ok but while it is completely wrong.  

__Formalization__ was easy, there is a _canonical_ form of the prolog and epilog that is part of the Microsoft spec for (hardware) [exceptions](https://docs.microsoft.com/en-us/cpp/build/arm64-exception-handling).  It is basically what is described above, but can't update the `sp` after you copied to the `fp` (setting the `fp` is still required).  So no alloca or dynamic extension of the stack during the code execution, but that is fine I wan't planning on using that away.  We can even call most functions, since ARM64 passes the first 8 parameters as registers so there is very little need to use the stack to pass parameters.  There is also an exact seq

__Verification__ was a little harder, but came in the form of the `dumpbin` tool.  When a function is decorated with a packed unwind data in the `.pdata` segment as described [here](https://docs.microsoft.com/en-us/cpp/build/arm64-exception-handling?view=msvc-160#packed-unwind-data). It will verify the opcodes of the prolog and epilog of your method and show any issues it detects.  I extended the `makefile` with the `unwindinfo` for our convenience.

A valid canonical prolog/epilog will give the following output:

```
c:\>nmake unwindinfo

<<snip>>

  00000000 00001000    Y     _start
   Start=40001000  Flag=1  FuncLen=38  RegF=0  RegI=0  H=0  CR=3  FrameSize=0x10
      [RawPdata=00001000 00E00039]
      +0000 stp  fp,lr,[sp,#-0x10]!  ; Actual=stp         fp,lr,[sp,#-0x10]!
      +0004 mov  fp,sp               ; Actual=mov         fp,sp
   Epilog #1 unwind:  (Offset=30)
      +0030 ldp  fp,lr,[sp],#0x10    ; Actual=ldp         fp,lr,[sp],#0x10
      +0034 ret                      ; Actual=ret
```

In case of an invalid version (store x22 instead of x21) you get something like this:

```
c:>nmake unwindinfo

<<snip>>

  00000008 00001038    Y     printf
   Start=40001038  Flag=1  FuncLen=5C  RegF=0  RegI=3  H=0  CR=3  FrameSize=0xC0
      [RawPdata=00001038 0663005D]
      +0000 stp  x19,x20,[sp,#-0x20]!; Actual=stp         x19,x20,[sp,#-0x20]!
      +0004 str  x21,[sp,#0x10]      ; Actual=str         x22,[sp,#0x10]
**** Expected opcode F9000BF5
      +0008 stp  fp,lr,[sp,#-0xA0]!  ; Actual=stp         fp,lr,[sp,#-0xA0]!
      +000C mov  fp,sp               ; Actual=mov         fp,sp
   Epilog #1 unwind:  (Offset=4C)
      +004C ldp  fp,lr,[sp],#0xA0    ; Actual=ldp         fp,lr,[sp],#0xA0
      +0050 ldr  x21,[sp,#0x10]      ; Actual=ldr         x21,[sp,#0x10]
      +0054 ldp  x19,x20,[sp],#0x20  ; Actual=ldp         x19,x20,[sp],#0x20
      +0058 ret                      ; Actual=ret
```

As you can see, it detected the error and gave both the expected assembly and machine code.  The tool is however far from perfect, I found several bug that I reported (the most notably is the misinterpretation of the RegF field).  Hopefully they will be fixed soon, but until then you should understand that an validation error doesn't necessary mean you made a mistake, it means you must triple check your code.

Off course, for all that to work you need to have `.pdata` segment in packed form.  You could write that by hand, but that would mean counting/calculating the size (in machine code instructions) of the method.  Not the most practical thing.  Luckily clang comes with some directives specific for that, unfortunately very undocumented directives.  

Here is what I figured out so far:

* Wrap the function between `.seh_proc <label>` and `.seh_endproc` directives
* End a prolog with the `seh_endprologue` directive (there is no explicit start prolog directive)
* wrap the epilog in `.seh_startepilogue` and `.seh_endepilogue` directives
* Follow each prolog/epilog instruction with [unwind code](https://docs.microsoft.com/en-us/cpp/build/arm64-exception-handling?view=msvc-170#unwind-codes) directive:
  * `end` unwind code becomes the `.seh_endfunclet` directive
  * `alloc_s`, `alloc_m`, `alloc_l` unwind codes all become the `.seh_stackalloc` directive
  * for all other unwind code, just prefix with `.seh_`, e.g. the `set_fp` unwind code becomes the `.seh_set_fp` directive

Most of them require parameters, like the first registry and/or the size of the memory. I basically had to take a guess what was expected and if it was wrong, figure it out based on the errors that where returned.

## Conclusion

We went a little deeper into functions, assembly directive and memory management.  With the exception of some very specific aspects of functions, we stayed rather close to the surface.  You should however be able to do most common tasks (with the exception of dynamic heap allocation) but there are definitely a lot off edge cases that aren't covered yet (and that I'm not even aware of). In the next lesson we fill in the last gaps, after that we will be focusing on the aarch64 instructions itself.
