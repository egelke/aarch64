# Lesson 0: Setup

In this lesson you'll be setting up a proper environment to develop for aarch64. At this end of this
tutorial you will have written a trivial application which you will have deployed, ran and debugged on your target machine.

While setting this up I encountered a lot of possible variations, each with their own set of advantages and disadvantages. I wanted something convenient & modern (non-deprecated) that didn't require any hacks. It did require a lot of rethinking and refactoring, but I came to a point where I'm happy with the result. Here are a few of the dead ends I did encounter:

* msvc tools support arm assembly files (integrated in VS via build customizations), but they use the deprecated "armasm" syntax. I switched to the clang toolset that uses the much more popular GNU ASM syntax.
* cmake for windows doesn't support arm assembly, so I went for nmake instead.
* VS doesn't support ASM syntax highlighting, so I started using Visual Studio Code as IDE instead.
* The Visual Studio provided llvm debug server crashes on the target machine, WinDbg doesn't so I use that.
* Out of the dozens ways of using WinDbg, the most comfortable setup was a process server on the target machine with WinDbg Preview on the Dev PC.
* There where some issue with linking standard C-functions, but since we aren't using C and it looked like a nice challenge, I decided to limit myself to native Windows API functions only.

As you can see, lots of hurdles to take, but I'm pleased with the final result. You may prefer a different setup, this is the one that works for me and this is the one I'll be using for the moment. Feel free to experiment and let me know how I could improve the setup.

## Installation and Setup

### Dev PC

The following must be installed on the development PC.

__[Visual Studio 2022](https://visualstudio.microsoft.com/)__ Community edition with the following packages:

* _Visual Studio Core Editor_
* _Desktop Development with C++_, with the default and following extra optional features
  * MSVC v143 - VC 2022 C++ ARM64 Build tools (latest)
  * C++ Clang tools for Windows (13.0.0 - x64/x86)

We will only be using Visual Studio's toolchain. So you will need a terminal with access to the VC build tools. You can use the VC provided commands or simply run "`%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat amd64_arm64`" command in (Windows) Terminal.

Behind the scenes, I also use it to write some C-programs to generate the corresponding assembly from it. If you are interested in that, let me know and I'll include it here.

__[Visual Studio Code](https://code.visualstudio.com/)__ with the following extensions:

* _ASM code Lens_: seems to be the most accurate syntax highlighter for aarch64 asm.

We will use this as the actual IDE.

For security reasons, I'll be using the `REMOTE_AARCH64_COMPUTER` environment variable with the name (or IP) of my target machine.

### Target PC

On the target PC, you need to install [WinDbg](https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/debugger-download-tools). Both the WinDbg Preview and SDK version seem to be working. The Preview version looks a lot nicer but is x64-only and therefore a lot slower. The SDK version shows it age but is available as arm64 executable and therefore a lot faster.

The most comfortable setup is when you use the [Process Server](https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/process-servers--user-mode-) included with the WinDbg SDK version, which also comes as an aarch64 executable. You run it on the target machine and connect to it from WinDbg Preview on the Dev PC. That way you have best of both worlds. Just make sure you don't forget to close the Process Server, its runs in the background and can be a major security issue when left unattended.

For easy deployment I also suggest you activate network sharing and expose a `Data` share.

## Project Structure

### Source file

Tthe source code exists of a single `.asm` file. It has some headers, a single code block and exposes a single procedure: `_start`. It is done this way because in Windows a program is a function called by the kernel, which the linker prepared when creating the executable. By default this is `mainCRTStartup`, but you can specify your own via the `/ENTRY` parameter with `link.exe`. I chose to change the name to "_start", since I didn't like that the default has "CRT" in its name because it stands for C-RunTime, and there is no C involved here.

The program ends when the entry function returns, the program exit code is the function return code.

As for the actual logic, it simply loads 2 constants in 2 temporary registers and adds them to a 3rd temporary register. You will need the debugger to actually verify it.

### Build files

The `mkdirs.bat` file will create the output directories, you will need to run it before executing your build or it will fail.

There is a `makefile` that targets `nmake`. It starts with some variables so it is easy to tweak to your likings and has various targets to build the executable. See below for the usage.

Both build files are generic and should (with the exception of the variables) be identical for all projects. This may of course evolve over the course of this tutorial.

### Output files

The intermediate output files are put in the `obj` directory, while the executable is put in the `bin` directory.

## Building

The makefile must be invoked with the `nmake` command with the VC build tools active. The following targets are available:

* __default__: build the project, produces an executable aarch64 executable with `clang` (llvm) as compiler and `link` (msvc) as linker, that seems to be giving the least amount of trouble
* __deploy__: uses `xcopy` to deploy to the target machine (default "`\\$(REMOTE_AARCH64_COMPUTER)\Data`")
* __clean__: deleted all fines from the `bin` and `obj` folders

## Debugging

On your target machine, start the `Process Server` with the following command:

```
c:\Users\bryan> dbgsrv -t tcp:port=5005
```

The first time it probably will ask you if you want to add an exception to the windows firewall, you probably want to accept. On the target machine that is, you only need to come back when you are done and when you want to shut down the Process Server (which you should definitely do).

On the Dev PC you start WinDbg Preview, via the file menu you need to "Connect to process Server", where your connection string is something like `tcp:Port=5005,Server=%REMOTE_AARCH64_COMPUTER%`. You need to replace `%REMOTE_AARCH64_COMPUTER%` with the actual computer name since environment variables do not work! You will be automatically redirected to the "Launch Executable (advdanced)" tab where you should enter `c:\Data\Sum.exe`. At this point you can leave the arguments and start directory empty. It will start your application on the target machine and show a WinDbg command window with the following output:

```
CommandLine: c:\data\sum.exe

************* Path validation summary **************
Response                         Time (ms)     Location
Deferred                                       srv*
Symbol search path is: srv*
Executable search path is:
ModLoad: 00007ff7`2b350000 00007ff7`2b359000   Sum.exe
ModLoad: 00007fff`746d0000 00007fff`74ac6000   ntdll.dll
ModLoad: 00007fff`74200000 00007fff`7435f000   C:\WINDOWS\System32\KERNEL32.DLL
ModLoad: 00007fff`70790000 00007fff`70d80000   C:\WINDOWS\System32\KERNELBASE.dll
(c018.bca0): Break instruction exception - code 80000003 (first chance)
ntdll!LdrpDoDebuggerBreak+0x30:
00007fff`747d6210 d43e0000 brk         #0xF000
```

In short: it is telling you the kernel loaded your program (`sum.exe`) and hit a breakpoint right before it started executing your application.

First we will tell it to stop at the entry point of your program, which is the `start` (the underscore gets dropped by the toolchain) in the `sum` module. You do this by typing the following command in at the bottom of the command window:

```
0:000> bm start
  1: 00007ff7`2b351000 @!"Sum!start"
```

The `bm` stands for "break method", the `sum` is the name of the module and `start` is the symbol to break at. Of course, you may also use the ribbon to set your breakpoint, the result is the same.

We are now ready to run your application by typing the following command in the command window:

```
0:000> g
Breakpoint 1 hit
Sum!start:
00007ff7`2b351000 d280026a mov         x10,#0x13
```

In order to see what is going on, bring up the "Registers" and "Disassembly" windows; either via the view-menu, the ribbons or with `alt+4` and `alt+7` respectively. Check out the registers `x10`, `x11` and `x9` while stepping trough the code with `F10` or the relevant buttons in the toolbar. After 3 steps you should see "a2" in the `x9` register. Execute the application to completion by triggering "Go" again, via the command windows (type `g`), the ribbon or by simply pressing `F5`.

At this point you can restart the same program again via the toolbox, menu or `Ctrl+Shift+F5`. You can only load a new program after you stop the current debugging session via the toolbox, menu or `Shift+F5`. As long as a debug session is active, you will not be able to load a new executable.

Afterwards, go back to the target PC and stop `dbgsrv` with TaskManager, which is apparently the official way to do it.

## Conclusion

That concludes the introduction, which should have taught you how to setup you environment, write a trivial application and run it on your target verifying it works with the aide of a debugger.
