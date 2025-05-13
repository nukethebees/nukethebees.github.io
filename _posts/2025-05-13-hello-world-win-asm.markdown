---
layout: post
title:  "Hello World! in Windows x64 asm"
date:   2025-05-13 18:00:00 +0100
categories: asm windows
---

This article shows `"Hello, world!"` in Windows x64 assembly using MASM with Visual Studio 2022[^1] (the full code is found [here](https://github.com/nukethebees/github_io/tree/main/hello_world_win_asm)).
We'll start by defining some external Windows API functions to let us write to the console and exit our `main` function[^2].

{% highlight nasm %}
extern GetStdHandle : PROC
extern WriteConsoleA : PROC
extern ExitProcess : PROC
{% endhighlight %}

Create a data segment to define some constants.

{% highlight nasm %}
.data
{% endhighlight %}

The carriage return (`\r`) and line feed characters (`\n`).

{% highlight nasm %}
CARRIAGE_RETURN equ 0Dh
LINE_FEED equ 0Ah
{% endhighlight %}

A constant for `GetStdHandle` to get a pointer to the standard output.

{% highlight nasm %}
STD_OUTPUT_HANDLE equ -11
{% endhighlight %}

A static byte array for our "hello world" message along with a newline and null terminator.
The `sizeof` function is needed as `WriteConsoleA` needs to know how many bytes to print[^3].

{% highlight nasm %}
HELLO_MSG db 'Hello, World!', CARRIAGE_RETURN, LINE_FEED, 0
HELLO_MSG_LEN = sizeof HELLO_MSG
{% endhighlight %}

Start the code segment and begin the `main` function definition.

{% highlight nasm %}
.code
main PROC
{% endhighlight %}

As our `main` function will be calling other functions we must first allocate some memory on the stack for these calls.
The Windows x64 calling convention requires allocating 32 bytes to store the first four eight-byte function parameters (regardless of whether they exist)[^4].
The x64 `call` instruction pushes the return address on the stack[^5] which adds another eight bytes to be stack allocated.
Finally, Windows uses a 16 byte stack alignment so we must increase our 40 bytes (32 + 8) to 48 to ensure correct alignment.

{% highlight nasm %}
sub rsp, 28h                  ; Allocate shadow space for function calls
{% endhighlight %}

We can write to the console using `WriteConsoleA`[^3] however its first parameter is a pointer to the standard output so we must first call `GetStdHandle`[^2] to get it.

{% highlight nasm %}
mov rcx, STD_OUTPUT_HANDLE    ; Set up the first argument for GetStdHandle
call GetStdHandle             ; Get the handle to the console.
{% endhighlight %}

We then set up the four arguments for `WriteConsoleA` in registers.
The return value from `GetStdHandle` (and all Windows functions) is stored in `rax`.

{% highlight nasm %}
mov rcx, rax                  ; Store the handle in rcx
lea rdx, HELLO_MSG            ; Load address of the message
mov r8, HELLO_MSG_LEN         ; Num bytes to write
mov r9, 0                     ; nullptr for the number of bytes written
{% endhighlight %}

Now we can write our string to the console!

{% highlight nasm %}
call WriteConsoleA            ; Call Windows API to print the message
{% endhighlight %}

Finally we deallocate our 40 bytes on the stack, return from the function, and end our function/code definitions.

{% highlight nasm %}
    add rsp, 28h                  ; Clean up stack
    mov rcx, 0                    ; Return zero
    call ExitProcess
main ENDP
END
{% endhighlight %}

[^1]: <https://learn.microsoft.com/en-us/cpp/assembler/masm/masm-for-x64-ml64-exe>
[^2]: <https://learn.microsoft.com/en-us/windows/console/getstdhandle>
[^3]: <https://learn.microsoft.com/en-us/windows/console/writeconsole>
[^4]: <https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention>
[^5]: <https://www.felixcloutier.com/x86/call>