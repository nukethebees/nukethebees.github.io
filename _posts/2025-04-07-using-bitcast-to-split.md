---
layout: post
title:  "[C++] Using std::bit_cast to convert byte arrays to values and back again"
date:   2025-04-07 17:30:00 +0100
categories: cpp asm
---

A common method of concatenating bytes is to use bit shifts and the `|` operator.
This can be tedious and potentially fail if there aren't 8 bits in a byte on your platform.

A more efficient method is to use `std::bit_cast` which reinterprets the bits of one datatype into another.

{% highlight cpp %}
#include <array>
#include <bit>

auto join(std::array<char, 4> chars) -> int {
    return std::bit_cast<int>(chars);
}

auto split(int num) -> std::array<char, 4> {
    return std::bit_cast<std::array<char, 4>>(num);
}
{% endhighlight %}

With compiler optimisations enabled, it can be implemented with a single instruction.

{% highlight nasm %}
chars$ = 8
int join(std::array<char,4>) PROC                    ; join, COMDAT
        mov     eax, ecx
        ret     0
int join(std::array<char,4>) ENDP                    ; join

num$ = 8
std::array<char,4> split(int) PROC       ; split, COMDAT
        mov     eax, ecx
        ret     0
std::array<char,4> split(int) ENDP       ; split
{% endhighlight %}