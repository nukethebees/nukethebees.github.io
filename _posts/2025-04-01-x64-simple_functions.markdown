---
layout: post
title:  "Simple C++ functions in x64"
date:   2025-03-31 19:10:38 +0100
categories: assembly
---

To learn x64 assembly (asm) I'll document the disassembly of some simple C++ functions.
The examples were [compiled on Godbolt](https://godbolt.org/z/4hEYfx3KW) with MSVC's latest version (v19.4) using  `O0` and `O2`.

# Identity Function

{% highlight cpp %}
auto identity(int x) {
    return x;
}
{% endhighlight %}

A simple identity function.

{% highlight nasm %}
x$ = 8
identity(int) PROC                              ; identity
        mov     DWORD PTR [rsp+8], ecx  
        mov     eax, DWORD PTR x$[rsp]
        ret     0
identity(int) ENDP                              ; identity
{% endhighlight %}

Let's go through it line by line.
The code uses the MASM syntax which takes the form of `instruction destination, source`.

{% highlight nasm %}
x$ = 8
{% endhighlight %}

`x$` is a simple constant.

{% highlight nasm %}
identity(int) PROC                              ; identity
{% endhighlight %}

This block denotes the start of the function.

{% highlight nasm %}
mov     DWORD PTR [rsp+8], ecx  
{% endhighlight %}

The `mov` instruction simply moves a value from one place to another.
The source and destination can either be a register or memory.
Square brackets denote accessing memory.
Here we move the value in register `ecx` into memory at the address 8 bytes above the stack pointer.

In C++ this would look like.

{% highlight cpp %}
    *(rsp + 8) = ecx;
{% endhighlight %}

By convention, the first four parameters of a Windows function are placed in registers `rcx`, `rdx`, `r8`, and `r9`.
These are then moved to stack memory when the function begins[^1].

{% highlight nasm %}
mov     eax, DWORD PTR x$[rsp]
{% endhighlight %}

`x` is copied from memory to register `eax` for the return value.
Integer return values are stored in `rax` (`eax` is simply the lower 32 bits of the full 64 bit register).

{% highlight nasm %}
ret     0
{% endhighlight %}

The `ret` instruction returns from the function to the calling address.

Now let's look at the optimised version of the function.

{% highlight nasm %}
x$ = 8
identity(int) PROC                              ; identity, COMDAT
        mov     eax, ecx
        ret     0
identity(int) ENDP                              ; identity
{% endhighlight %}

`x` is just moved from `ecx` into `eax`. That's it.

# +1 function

{% highlight cpp %}
auto add1(int x) {
    return x + 1;
}
{% endhighlight %}

A simple increment function.

{% highlight nasm %}
x$ = 8
add1(int) PROC                                  ; add1
        mov     DWORD PTR [rsp+8], ecx
        mov     eax, DWORD PTR x$[rsp]
        inc     eax
        ret     0
add1(int) ENDP                                  ; add1
{% endhighlight %}

The `inc` instruction adds `1` to its only operand.

{% highlight nasm %}
x$ = 8
add1(int) PROC                                  ; add1, COMDAT
        lea     eax, DWORD PTR [rcx+1]
        ret     0
add1(int) ENDP    
{% endhighlight %}

With optimisations we encounter the `lea` instruction.
It stands for "load effective address" and it stores the result of the rhs expression in the destination (it doesn't actually access memory).
It's used for calculating memory offsets but it's often used for efficient mathematics[^2].

In this case we're storing `rax+1` in the `eax` register so we can return immediately.

# Integer multiplication

{% highlight cpp %}
auto multiply(int x, int y) {
    int z{x * y};
    return z;
}
{% endhighlight %}

Integer multiplication with a stack variable.

{% highlight nasm %}
z$ = 0
x$ = 32
y$ = 40
multiply(int,int) PROC                       ; multiply
$LN3:
        mov     DWORD PTR [rsp+16], edx
        mov     DWORD PTR [rsp+8], ecx
        sub     rsp, 24
        mov     eax, DWORD PTR x$[rsp]
        imul    eax, DWORD PTR y$[rsp]
        mov     DWORD PTR z$[rsp], eax
        mov     eax, DWORD PTR z$[rsp]
        add     rsp, 24
        ret     0
multiply(int,int) ENDP                       ; multiply
{% endhighlight %}

This example has more to go through but it's still simple.

{% highlight nasm %}
mov     DWORD PTR [rsp+16], edx
mov     DWORD PTR [rsp+8], ecx
sub     rsp, 24
{% endhighlight %}

The function prolog. 
Parameters `x` and `y` are stored in two of the four reserved registers and then moved to memory.
The stack pointer address is reduced by 24 to account for the three variables in the function (`8*3=24`).
All memory for the function is reserved up front.
Variables can then be accessed with offsets from `rsp` instead of having to move it about.

{% highlight nasm %}
mov     eax, DWORD PTR x$[rsp]
imul    eax, DWORD PTR y$[rsp]
mov     DWORD PTR z$[rsp], eax
mov     eax, DWORD PTR z$[rsp]
{% endhighlight %}

`x` is moved from memory into the return register `eax` and then multiplied by `y`.
This result is moved into `z`'s address in memory before being moved back to `eax` as the return value.
Somewhat wasteful.

{% highlight nasm %}
add     rsp, 24
ret     0
{% endhighlight %}

We reset the stack pointer to its original address and return.

{% highlight nasm %}
x$ = 8
y$ = 16
multiply(int,int) PROC                       ; multiply, COMDAT
        imul    ecx, edx
        mov     eax, ecx
        ret     0
multiply(int,int) ENDP                       ; multiply
{% endhighlight %}

For the optimised version the two parameters are directly multiplied in the registers and moved to `eax`.


[^1]: <https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-170>
[^2]: <https://stackoverflow.com/questions/1658294/whats-the-purpose-of-the-lea-instruction>