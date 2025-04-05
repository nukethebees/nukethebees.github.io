---
layout: post
title:  "Optimised x64 assembly for a summing loop function"
date:   2025-04-05 12:00:00 +0100
categories: cpp
---

Here's another simple function to analyse. It sums all the values from `0` to `N` (exclusive) e.g. `sum(4) = 6`.
Let's take a look at the asm produced by MSVC, GCC and Clang.

{% highlight cpp %}
unsigned int sum(unsigned int N) {
    unsigned int x{0};
    for (unsigned int i{0}; i < N; ++i) {
        x += i;
    }
    return x;
}
{% endhighlight %}

# MSVC

The first block zeroes out the registers to be used.
If `N <= 1` then the loop skips to the end and returns `0`.
We'll look at the loop in more detail below.

{% highlight nasm %}
N$ = 8
unsigned int sum(unsigned int) PROC    ;   
        xor     r10d, r10d             ; Clear r10, rdx, r8, and rax
        mov     edx, r10d              ;
        mov     r8d, r10d              ; 
        mov     eax, r10d              ; return value (x)
        
        cmp     ecx, 2                 ; Evaluate N - 2
        jb      SHORT $LC10@sum        ; Jump if CF = 1 from underflow
        lea     r9d, DWORD PTR [rcx-1] ; r9 = N-1
        npad    11                     ; 
$LL11@sum:                             ;
        inc     r8d                    ; ++r8d
        add     edx, eax               ; rdx += eax
        add     r8d, eax               ; r8d += eax
        add     eax, 2                 ; eax += 2
        cmp     eax, r9d               ; Evaluate eax - (N-1)
        jb      SHORT $LL11@sum        ; Next iter
$LC10@sum:                             ;
        cmp     eax, ecx               ; Evaluate x - N
        cmovae  eax, r10d              ; eax = (eax - N) >= 0 ? 0 : eax
        add     eax, r8d               ; 
        add     eax, edx               ; 
        ret     0                      ;
unsigned int sum(unsigned int) ENDP    ;                         
{% endhighlight %}

Here's the pattern of the three registers used in the loop.

{% highlight nasm %}
i   -> 0, 1, 2, 3
r8d -> 1, 4, 9, 16
edx -> 0, 2, 6, 12
eax -> 2, 4, 6, 8

r8d = (i+1)**2
edx = (i+1) * i
eax = (i+1) * 2
{% endhighlight %}

I made this simple Python script to trace the loop progression and confirm my work.

{% highlight python %}
def sum(N):
    r8d = 0
    edx = 0
    eax = 0

    if (N > 1):
        while True:
            r8d += 1
            edx += eax
            r8d += eax
            eax += 2
            next_iter = (eax - (N-1)) < 0

            print(f"i: {i}, r8d: {r8d}, edx: {edx}, eax: {eax}, loop again: {next_iter}")
            if not next_iter:
                break
    if (eax - N) >= 0:
        eax = 0

    print(f"Final r8d: {r8d}, edx: {edx}, eax: {eax}")

    return eax + r8d + edx

for i in range(10):
    print(f"Iter: {i}")
    print(f"Result: {sum(i)}\n")
{% endhighlight %}

This gives the following output.

<details>
<summary>
<b>Python script output</b>
</summary>
{% highlight text %}
Iter: 0
Final r8d: 0, edx: 0, eax: 0
Result: 0

Iter: 1
Final r8d: 0, edx: 0, eax: 0
Result: 0

Iter: 2
i: 2, r8d: 1, edx: 0, eax: 2, loop again: False
Final r8d: 1, edx: 0, eax: 0
Result: 1

Iter: 3
i: 3, r8d: 1, edx: 0, eax: 2, loop again: False
Final r8d: 1, edx: 0, eax: 2
Result: 3

Iter: 4
i: 4, r8d: 1, edx: 0, eax: 2, loop again: True
i: 4, r8d: 4, edx: 2, eax: 4, loop again: False
Final r8d: 4, edx: 2, eax: 0
Result: 6

Iter: 5
i: 5, r8d: 1, edx: 0, eax: 2, loop again: True
i: 5, r8d: 4, edx: 2, eax: 4, loop again: False
Final r8d: 4, edx: 2, eax: 4
Result: 10

Iter: 6
i: 6, r8d: 1, edx: 0, eax: 2, loop again: True
i: 6, r8d: 4, edx: 2, eax: 4, loop again: True
i: 6, r8d: 9, edx: 6, eax: 6, loop again: False
Final r8d: 9, edx: 6, eax: 0
Result: 15

Iter: 7
i: 7, r8d: 1, edx: 0, eax: 2, loop again: True
i: 7, r8d: 4, edx: 2, eax: 4, loop again: True
i: 7, r8d: 9, edx: 6, eax: 6, loop again: False
Final r8d: 9, edx: 6, eax: 6
Result: 21

Iter: 8
i: 8, r8d: 1, edx: 0, eax: 2, loop again: True
i: 8, r8d: 4, edx: 2, eax: 4, loop again: True
i: 8, r8d: 9, edx: 6, eax: 6, loop again: True
i: 8, r8d: 16, edx: 12, eax: 8, loop again: False
Final r8d: 16, edx: 12, eax: 0
Result: 28

Iter: 9
i: 9, r8d: 1, edx: 0, eax: 2, loop again: True
i: 9, r8d: 4, edx: 2, eax: 4, loop again: True
i: 9, r8d: 9, edx: 6, eax: 6, loop again: True
i: 9, r8d: 16, edx: 12, eax: 8, loop again: False
Final r8d: 16, edx: 12, eax: 8
Result: 36
{% endhighlight %}
</details>
<br>

For even numbers of `N`:
{% highlight text %}
x = r8d + edx
{% endhighlight %}
 
For odd numbers:

{% highlight text %}
x = r8d + edx + eax
{% endhighlight %}

where

{% highlight text %}
n = N/2 (integer division)
m = n+1
r8d = m**2
edx = m*n
eax = m*2
{% endhighlight %}
 
As a final expression, the loop could be described as: 

{% highlight text %}
x = m**2 + m*n + (N % 2) * m*2
{% endhighlight %}

# GCC

{% highlight nasm %}
sum(unsigned int):
        test    edi, edi
        je      .L4
        xor     eax, eax
        xor     edx, edx
        test    dil, 1
        je      .L3
        mov     eax, 1
        cmp     edi, 1
        je      .L1
.L3:
        lea     edx, [rdx+1+rax*2]
        add     eax, 2
        cmp     edi, eax
        jne     .L3
.L1:
        mov     eax, edx
        ret
.L4:
        xor     edx, edx
        mov     eax, edx
        ret
{% endhighlight %}

# Clang

Clang transforms the loop into a simple constant-time mathematical expression.
First prize.

{% highlight nasm %}
sum(unsigned int):
        test    edi, edi                ; check N & N
        je      .LBB0_1                 ; Jump to end if N == 0
        lea     eax, [rdi - 1]          ; rax = N - 1 
        lea     ecx, [rdi - 2]          ; rcx = N - 2 
        imul    rcx, rax                ; rcx = (N - 1) * (N - 2)
        shr     rcx                     ; rcx /= 2
        lea     eax, [rdi + rcx]        ; eax = ((N-1)*(N-2)) / 2 + N
        dec     eax                     ; eax = ((N-1)*(N-2)) / 2 + (N - 1)
        ret                             ; 
.LBB0_1:                                ;
        xor     eax, eax                ;
        ret                             ;
{% endhighlight %}
