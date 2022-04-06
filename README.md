# Windows AARCH64 Tutorial

A set of project to learn aarch64 (ARM64) assembly language for _Windows_.  

While there is some information out there of how to develop for ARM Assembly on Linux, there is virtually nothing available for ARM assembly for Windows.  Granted, it is far from popular and we should all be developing in higher
languages like C, C++ or C# its always nice to learn what is going on under the hood.

So it took it upon me to create a series of project that explain aarch64 (aka arm64) assembly language for Windows.
While I have over 20 year of experience in programming, I have never been a low-level developer.  This tutorial is really on eye leading the blind, so if you spot any mistakes, please feel free to comment or reach out to me in any other way.

I'm planning to make a YouTube series on that, but until then you will have to do with the code.

Projects so far:

0. **Sum**: Setup of the environment, including debugging and a leaf functions
1. **HelloWorld**: constants, initialized global data, temp registers and unchained functions
2. **MeaningOfLife**: register aliases, uninitialized global data, saved registers and chained functions (WIP)
3. **ArgEcho**: local allocated data and loops (WIP)
4. ...

## Prerequisites

* __Dev PC__: an x64 Windows PC with sufficient disk free
* __Target PC__: Windows PC running on aarch64 (aka ARM64)

See Lesson 0 for how te set it up.

Personally I'm using a first generation Microsoft Surface Pro X as my target PC, but you could use other types of devices too.