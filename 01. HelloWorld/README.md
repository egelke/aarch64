# Lesson 1: Hello World

Now that we have our environment setup, it is time to start with our first real world program.  As is tradition, that is off course the classical "Hello Wold!".

This lesson focus on 2 topics, initialized global data and basic function calling.  Later lessons will extend this with uninitialized and local data and more types of function calling.

## Data

Since ARM is a RISC architecture, there is a pretty explicit boundary between registers and memory.  In RISC, instructions (with a few dedicated exceptions) can only work with the data in the registry.

### Registers

ARM has 32 standard 64bit registers, of which 30 are "[general-purpose](https://developer.arm.com/documentation/102374/0101/Registers-in-AArch64---general-purpose-registers)" that can be addressed as full 64bit registers by using "x" or 32bit by using "w".  There are also 2 [special](https://developer.arm.com/documentation/102374/0101/Registers-in-AArch64---other-registers), with the x30/lr register somewhere in between general purpose and special.  As if that isn't confusing enough, this is only true when you look at from a hardware perspective.  From a software perspective the general-purpose register are sub decided according to their usage as explained [here](https://docs.microsoft.com/en-us/cpp/build/arm64-windows-abi-conventions?view=msvc-170#integer-registers).

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

(Immediate, labels, constants, initialized global data, constants and stack.)

### Transfer

(Load & Store)

## Functions

(calling conventions, leaf & non-leaf unchained functions)