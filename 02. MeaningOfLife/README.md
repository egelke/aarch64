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

Why do we do this? Mainly to extend our knowledge with regards to functions.  We add the concept of chained function, learn how to use saved registers.  In order to not learn things that aren't future proof, we immediately learn how to make the chained functions exception safe; while not actually learning exceptions.

Additionally we learn a few additional basic concepts such as registers aliases and how to use uninitialized global data.

## Assembly syntax

## Stack

## Chained functions
