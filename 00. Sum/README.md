# Lesson 0: Setup

In this lesson we make sure you are setup with a proper environment to develop for aarch64.  At this end of this
tutorial you will have written a very basic application which you will have deployed, ran and debugged on your target machine, an aarch64 Windows machine.

While setting this up I encountered a lot of possible variations, each with their own set of advantages and disadvantages.  I wanted something modern (non-deprecated) that didn't require any hacks.  It did require a lot of
rethinking and refactoring, but I came to a point I'm happy with the result.  Here are a few of the dead ends I did encounter:

* msvc tools support arm assembly files (integrated in VS via build customizations), but it uses the deprecated "armasm" syntax not the much more popular GNU syntax which is supported by the clang toolset.
* cmake for windows doesn't support arm assembly, so I went for nmake instead.
* VS doesn't support syntax highlighting, so I went for Visual Studio Code instead.
* The provided llvm debug server provided by VS crashes on the target machine, WinDbg doesn't so I use that.
* While WinDbg supports remote debugging, it was much easier to simply run the GUI on the client  machine
* There where some issue with linking standard C-functions, but since we aren't using C and it looked like a nice challenge, I decided to limit myself to native Windows API functions only.

As you can see, lots of hurdles to take, but in the end I'm rather pleased with the result.  You may prefer a different setup, this is the one that works for me and this is the one I'll be using for the moment.  Feel free to experiment and let me know why yours is superior.

## Prerequisites

* __Dev PC__: Windows x64 with sufficient power
* __Target PC__: Windows aarch65/arm64 PC like the Microsoft Surface Pro X

## Installation and Setup

### Dev PC
The followin must be installed on the development PC.

__[Visual Studio 2022](https://visualstudio.microsoft.com/)__ Community edition with the following packages:

* _Visual Studio Core Editor_
* _Desktop Development with C++_, with the default and following extra optional features
  * MSVC v143 - VC 2022 C++ ARM64 Build tools (latest)
  * C++ Clang tools for Windows (13.0.0 - x64/x86)

We will use this only for the build tool and maybe to write a C-program and generate assembly from it, but more on
that later.

__[Visual Studio Code](https://code.visualstudio.com/)__ with the following extensions:

* _ASM code Lens_: seems to be the most accurate syntax highlighter for aarch64.

We will use this to write the actual assembly code.

We will need to set the `REMOTE_AARCH64_COMPUTER` environment variable with the name (or IP) of your target machine.
You need also need terminal with access to the VC build tools, you can use the VC provides commands or simply run "`%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat amd64_arm64`" command. 

### Target PC

On the target PC, you need to install [WinDbg](https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/debugger-download-tools).  Both the WinDbg Preview and SDK version seems to be working, the Preview version looks a lot nicer but is x64-only and therefore a lot slower, the SDK version shows it age but is available as arm64 executable and therefore a lot quicker.

For easy deployment I also suggest you activate network sharing and you expose a `Data` share.

## Project Structure

### Source file

At this time the source code exists of a single `.asm` file.  It has some headers, a single code block and exposes a single procedure: `sum`.  It is done this way because in Windows a program is a function called by the kernel, which the linker prepared when creating the executable.  By default that is `mainCRTStartup`, but you can specify your own via the `/ENTRY` parameter with `link.exe`.  I opted to change the name to "sum", since I didn't like that the default has CRT which stands for C-RunTime, while there is not C involved here.

The program ends when the entry function return, the program exit code is the function return code.

As for the actual logic, it simply loads 2 constants in 2 temporally registers and adds them to a 3rd temporary register.  You will need the debugger to actually verify it.

### Build files

The `mkdirs.bat` file will create the output directories, you will need to run it before executing your build or it will fail.

There is a `makefile` that targets `nmake`.  It starts with some variables so it is easy to tweak to your likings and has various targets to build the executable. See below for the usage.

Both build files are generic, and should with the exception of the variables be identical for all project.  It may off course evolve over the course of this tutorial.

### Output files

The intermediate output files are put inside the `obj` directory, while the executable is put inside the `bin` directory.

## Building

The makefile must be invoked with the `nmake` command with the VC build tools active.  The following targets are available:

* __default__: build the project, produces an executable aarch64 executable with clang (llvm) as compiler and link (msvc) as linker, that seems to be giving the least amount of trouble
* __deploy__: uses xcopy to deploy to the target machine (default "`\\$(REMOTE_AARCH64_COMPUTER)\Data`")
* __clean__: removes the builds by deleting all fines from the `bin` and `obj` folder

## Debugging

TODO
