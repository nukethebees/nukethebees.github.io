---
layout: post
title:  "Optimised x64 assembly for a summing loop function"
date:   2025-04-04 19:20:00 +0100
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
eax -> 0, 2, 4, 6

r8d = (i+i)**2
edx = (i+1) * i
eax = 2*i
{% endhighlight %}

In the final loop this gives a result of `x = (i+1)**2 + (i+1)*i + 2*i`.

{% highlight nasm %}
; N = 4

; First iteration
; r8d += 1 = 1
; edx += 0 = 0
; r8d += 0 = 1
; eax += 2 = 2
; cmp (eax - r9d) -> (2 - 3)
; CF == 1 -> next iteration

; Second iteration
; r8d += 1 = 2
; edx += eax = 2
; r8d += eax = 4
; eax += 2 = 4
; cmp (4 - 3)
; CF != 1 -> continue

; cmp (eax - ecx) -> (4 - 4)
; CF == 0, eax = 0
; eax += 4
; eax += 2
; return 6

; (untaken third iteration)
; r8d += 1 = 5
; edx += eax = 6
; r8d += eax = 9
; eax += 2 = 6

; (untaken fourth iteration)
; r8d += 1 = 10
; edx += eax = 12
; r8d += eax = 16
; eax += 2 = 8


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
