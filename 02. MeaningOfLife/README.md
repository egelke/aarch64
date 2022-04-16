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

The __Heap__ and __stack__ are different, you need to be initialize and managed them via your code.  The stack is described [here](#stack), while for the heap you have to be a little patient and wait for the next lesson.  

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

## Functions
