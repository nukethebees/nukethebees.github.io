---
layout: post
title:  "Simple C++ functions in x64"
date:   2025-03-31 19:10:38 +0100
categories: assembly
---

To learn x64 assembly (asm) I'll document the disassembly of some simple C++ functions.
The examples were [compiled on Godbolt](https://godbolt.org/z/vch5oPs6e) with MSVC's latest version (v19.4) using  `O0` and `O2`.

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
This is using MASM syntax which takes the form of `instruction destination, source`.

{% highlight nasm %}
mov     DWORD PTR [rsp+8], ecx  
{% endhighlight %}

The `mov` instruction simply moves a value from one place to another.
Here we move the value in register `ecx` into memory at the address 8 bytes above the stack pointer.
The square brackets indicate that we're accessing an address in memory.
In C++ this would look like.

{% highlight cpp %}
    *(rsp + 8) = ecx;
{% endhighlight %}

By convention, the first four parameters of a Windows function are placed in registers `rcx`, `rdx`, `r8`, and `r9`.
These are then moved to memory when the function begins[^1].

{% highlight nasm %}
mov     eax, DWORD PTR x$[rsp]
{% endhighlight %}

The value of `x` is now copied from RAM to register `eax` for our return value.
Integer return values are passed through `rax` (`eax` is simply the lower 32 bits of the full 64 bit register).

{% highlight nasm %}
ret     0
{% endhighlight %}

The `ret` instruction then jumps back to the calling address.
Easy peasy.

Now let's look at the optimised version of the function.

{% highlight nasm %}
x$ = 8
identity(int) PROC                              ; identity, COMDAT
        mov     eax, ecx
        ret     0
identity(int) ENDP                              ; identity
{% endhighlight %}

With optimisations we don't need to bother with accessing memory at all.
We simply move `x` from `ecx` into `eax`. That's it.

# +1 function

{% highlight cpp %}
auto add1(int x) {
    return x + 1;
}
{% endhighlight %}

This time we're going to add `1` to our input before returning it.

{% highlight nasm %}
x$ = 8
add1(int) PROC                                  ; add1
        mov     DWORD PTR [rsp+8], ecx
        mov     eax, DWORD PTR x$[rsp]
        inc     eax
        ret     0
add1(int) ENDP                                  ; add1
{% endhighlight %}

The only difference this time is we use the `inc` instruction before returning.
As expected, it adds `1` to its only operand.

And now the optimised version.

{% highlight nasm %}
x$ = 8
add1(int) PROC                                  ; add1, COMDAT
        lea     eax, DWORD PTR [rcx+1]
        ret     0
add1(int) ENDP    
{% endhighlight %}

Here we're encountering the `lea` instruction.
It stands for "load effective address" and it stores the result of the expression in the destination.
It's just for calculating memory offsets (it doesn't actually access memory) but it's often used for efficient mathematics[^2].

In this case we're storing `rax+1` in the `eax` register so we can return immediately.

[^1]: <https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-170>
[^2]: <https://stackoverflow.com/questions/1658294/whats-the-purpose-of-the-lea-instruction>