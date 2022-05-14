# Windows AARCH64 Tutorial

A set of projects to learn aarch64 (ARM64) assembly language for _Windows_.

While there is some information out there on how to develop for ARM Assembly on Linux, there is virtually nothing available for ARM assembly for Windows. Granted, it is far from popular and we should all be developing in higher-level languages like C, C++ or C# anyway, but it's always nice to learn what is going on under the hood.

So I took it upon me to create a series of projects to explain the aarch64 (aka ARM64 or 64bit ARM) assembly language for Windows. While I have over 20 year of experience in programming, I have never been a low-level developer. So if you spot any mistakes, feel free to comment or reach out to me in any other way.

This tutorial assumes you have some experience with computer programming -- you should be familiar with at least the basics of a computer's inner workings. The main focus is the ARM assembly language as used on a Windows machine. For example, I'll explain how to use the stack since that is something you need to do yourself, but I won't go into the details of memory management as this is handled by the Windows OS.

I'm planning to make a YouTube series on this. Until then, you'll have to do with these projects.

Projects so far:

0. **[Sum](00.%20Sum/)**: setup of the environment, including debugging and leaf functions
1. **[HelloWorld](01.%20HelloWorld/)**: constants, initialized global data, temp registers and unchained functions
2. **[MeaningOfLife](02.%20MeaningOfLife/)**: register aliases, uninitialized global data, saved registers, local stack data and chained functions
3. **ArgEcho**: multiple source files, includes, macros, expressions, heap data and branches (WIP)
4. **HowLong?**: system registers, ... (planned)
5. ...

## Prerequisites

* __Dev PC__: an x64 Windows PC with sufficient disk free
* __Target PC__: Windows PC running on aarch64 (aka ARM64)

See Lesson 0 for how te set it up.

Personally I'm using a first generation Microsoft Surface Pro X as my target PC, but you could use any other type of Windows device if you prefer.

## References

This series is made as a tutorial, meaning you learn by example. It isn't a manual nor a course that will explain aarch64 step by step, instead it is a series of examples that will help you to figure it out yourself. Here's a set of links I found useful in my journey:

### developer.arm.com (official)

The following references are provided by ARM inc itself:

* [Programmer's guide](https://developer.arm.com/documentation/102374/latest/)
* [armclang reference guide](https://developer.arm.com/documentation/100067/0612/armclang-Integrated-Assembler?lang=en)
* Instruction summary of the [ARMASM reference guide](https://developer.arm.com/documentation/dui0802/b/A64-General-Instructions/A64-general-instructions-in-alphabetical-order)[^1]
* [Instruction reference](https://developer.arm.com/documentation/ddi0602/latest)

[^1]: The armasm reference guide has nice a summary of instructions, the armclang reference guide (the examples all use clang, not asm) doesn't.

### Other sources

* [Presentation of Matteo Franchin (ARM)](https://armkeil.blob.core.windows.net/developer/Files/pdf/graphics-and-multimedia/ARMv8_InstructionSetOverview.pdf)
* [Microsoft's explanation for C++ project](https://docs.microsoft.com/en-us/cpp/build/configuring-programs-for-arm-processors-visual-cpp?view=msvc-170)
* [modexp blog post](https://modexp.wordpress.com/2018/10/30/arm64-assembly/)
