---
layout: post
title:  "[C++] std::string_view generates worse assembly than pointer + size on Windows"
date:   2025-04-05 22:00:00 +0100
categories: cpp asm
---

After reading the Windows x64 calling convention documentation[^1], I noticed that functions parameters greater than 8 bytes are passed by reference instead of via registers.
Given the recent push in C++ towards views like `std::span` and `std::string_view`, I wondered if these 16 byte containers would add a performance overhead compared to the C-style pointer and size.

With `std::string_view` this is indeed the case[^2]. Let's use a simple function which returns the final character in a string.

{% highlight cpp %}
#include <cstddef>
#include <string_view>

char get_last(char const * str, std::size_t i) {
    return str[i-1];
}
char get_last_sv(std::string_view str) {
    return str.back();
}
{% endhighlight %}

Using `str::string_view` requires double the instructions as the two halves of the `string_view` must be loaded from memory before we can access the byte.

{% highlight nasm %}
str$ = 8
i$ = 16
char get_last(char const*,unsigned __int64) PROC                   ; get_last, COMDAT
        movzx   eax, BYTE PTR [rcx+rdx-1]
        ret     0
char get_last(char *,unsigned __int64) ENDP                   ; get_last

str$ = 8
char get_last_sv(std::basic_string_view<char,std::char_traits<char> >) PROC ; get_last_sv, COMDAT
        mov     rdx, QWORD PTR [rcx+8]
        mov     rax, QWORD PTR [rcx]
        movzx   eax, BYTE PTR [rdx+rax-1]
        ret     0
char get_last_sv(std::basic_string_view<char,std::char_traits<char> >) ENDP ; get_last_sv
{% endhighlight %}

When the functions are used together, the difference still exists. The same double memory read cost must be paid.

{% highlight cpp %}
char sum(char const* str, std::size_t i, std::string_view str2) {
    return get_last(str, i) + get_last_sv(str2);
}
{% endhighlight %}

{% highlight nasm %}
str$ = 8
i$ = 16
str2$ = 24
char sum(char const *,unsigned __int64,std::basic_string_view<char,std::char_traits<char> >) PROC ; sum, COMDAT
        mov     r9, QWORD PTR [r8]
        mov     rax, QWORD PTR [r8+8]
        movzx   eax, BYTE PTR [rax+r9-1]
        add     al, BYTE PTR [rcx+rdx-1]
        ret     0
char sum(char const *,unsigned __int64,std::basic_string_view<char,std::char_traits<char> >) ENDP ; sum
{% endhighlight %}

However if the compiler has full knowledge of the strings and their sizes, it can transform the calls into equivalent instructions.

{% highlight cpp %}
int main() {
    constexpr auto str0{"000"};
    constexpr auto str1{std::string_view{"000"}};

    volatile auto gl{get_last(str0, 3)};
    volatile auto gl2{get_last_sv(str1)};

    return gl + gl2;
}
{% endhighlight %}

{% highlight nasm %}
gl2$ = 8
gl$ = 16
main    PROC                                            ; COMDAT
        mov     BYTE PTR gl$[rsp], 48           ; 00000030H
        mov     BYTE PTR gl2$[rsp], 48                    ; 00000030H
        movsx   ecx, BYTE PTR gl2$[rsp]
        movsx   eax, BYTE PTR gl$[rsp]
        add     eax, ecx
        ret     0
main    ENDP
{% endhighlight %}

[^1]: <https://godbolt.org/z/8Yasvqbhb>
[^2]: <https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-170>