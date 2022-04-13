    .arch armv8-a

    .include "cfunc.inc.asm"
    
    .equ STD_OUTPUT_HANDLE, -11

    .global printstr
    
    pattern .req x19
    string  .req x20
    strlen  .req x21
    stdOut  .req x22
    wchar   .req x23
    buffer  .req x24

    .equ writen, 0x10                   //define the fp-offset of the writen local variable

printstr:
    cfunc_prolog printstr, RegI=6, alloc=0x10

    //keep the paramters
    mov pattern, x0                 //the format pattner
    mov string, x1                  //the string to write

    //init other variables
    mov wchar, #2                   //2 bytes per char
    
    //get the length of the pattern
    mov x0, pattern                 //lpString: the pattern
    bl lstrlenW                     //call https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lstrlenw
    mul strlen, x0, wchar           //Return value: save the strlen as bytes len

    //get the length of the string
    mov x0,string                   //lpString: the string
    bl lstrlenW                     //call https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lstrlenw
    madd strlen, x0, wchar, strlen  //Return value: add the bytes to the previous length

    //obtain the memory
    bl GetProcessHeap               //hHeap: call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    mov x1, xzr                     //dwFlags: null
    add x2, strlen, #1              //dwBytes: number of bytes + 1 for the '\0' char at the end
    bl HeapAlloc                    //call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapalloc
    mov buffer, x0                  //Return value: keep for later

    //format the string
    mov x0, buffer                  //unnamedParam1: buffer
    mov x1, pattern                 //unnamedParam2: pattern
    mov x2, string                  //dynamic param0: the value to print (saved param)
    bl wsprintfW                    //call https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-wsprintfw
    mul strlen, x0, wchar           //Return value: save the generates string len a byte len

    //write the buffer to stdOut
    mov x0, STD_OUTPUT_HANDLE       //nStdHandle: STD_OUTPUT_HANDLE = -11
    bl GetStdHandle                 //hFile: call https://docs.microsoft.com/en-us/windows/console/getstdhandle
    mov x1, buffer                  //lpBuffer: calculate the address of the buffer variable (offset to the fp)
    mov x2, strlen                  //nNumberOfBytesToWrite: the bytes to write, obtained from the wsprintfW result 
    add x3, fp, writen              //lpNumberOfBytesWritten: calcuate the address of the writen variable (offset to the fp)
    mov x4, xzr                     //lpOverlapped: NULL
    bl WriteFile                    //call https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-writefile

    //free the memory
    bl GetProcessHeap               //hHeap: call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    mov x1, xzr                     //dwFlags: NULL
    mov x2, buffer                  //lpMem: the buffer to free
    bl HeapFree                     //call https://docs.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapfree

    //return success
    ldr x0, [fp, writen]            //load the date from the written variable into x0 to be returned

    cfunc_epilog RegI=6, alloc=0x10

    .end