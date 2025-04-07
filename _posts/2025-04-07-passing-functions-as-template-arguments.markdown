---
layout: post
title:  "[C++] Passing functions as template arguments"
date:   2025-04-07 18:47:00 +0100
categories: cpp asm
---

Function pointers allow us to inject functionality into other functions.
A common use case is passing comparison functions into a sorting function.

One issue with function pointers is the compiler cannot optimise the function call as it isn't known until runtime.
There is also a slight performance overhead from having to load the function's address into a register before it can be called.

If we know what function we want to call at compile time, these issues can be solved by passing the pointer as a template argument.
The compiler then has full knowledge of the call and can apply the usual optimisations to it.

Here is a trivial example.

{% highlight cpp %}
template <auto fn>
auto call_fn(auto value) {
    return fn(value);
}

int main() {
    volatile auto x{call_fn<[](auto x) { return x + 1;}>(1)};

    return 0;
}
{% endhighlight %}

The asm output shows the call is completely optimised out and the result is used directly.

{% highlight nasm %}
value$ = 8
auto call_fn<`int main(void)'::`2'::<lambda_1_>{},int>(int) PROC ; call_fn<`main'::`2'::<lambda_1_>{},int>, COMDAT
        lea     eax, DWORD PTR [rcx+1]
        ret     0
auto call_fn<`int main(void)'::`2'::<lambda_1_>{},int>(int) ENDP ; call_fn<`main'::`2'::<lambda_1_>{},int>

this$ = 8
x$ = 16
auto `int main(void)'::`2'::<lambda_1_>::operator()<int>(int)const  PROC     ; `main'::`2'::<lambda_1_>::operator()<int>, COMDAT
        lea     eax, DWORD PTR [rdx+1]
        ret     0
auto `int main(void)'::`2'::<lambda_1_>::operator()<int>(int)const  ENDP     ; `main'::`2'::<lambda_1_>::operator()<int>

x$ = 8
main    PROC                                            ; COMDAT
        mov     DWORD PTR x$[rsp], 2
        xor     eax, eax
        ret     0
main    ENDP
{% endhighlight %}