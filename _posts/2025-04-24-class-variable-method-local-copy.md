---
layout: post
title:  "[C++] Saving class members as local variables can reduce memory accesses"
date:   2025-04-24 21:00:00 +0100
categories: cpp asm
---

In certain contexts it can be more efficient to make local copies of class members and then update the instance class at the end.
I'll illustrate this with an example[^1].

The following struct models a lexer's state with a `string_view` and some positional variables.
The methods `foo` and `bar` will compare the use of local variables.

{% highlight cpp %}
#include <string_view>

struct Lex {
    std::string_view file;
    std::size_t i;
    std::size_t i_offset;

    void foo();
    void bar();
};
{% endhighlight %}

`foo` uses the members directly.
It consists of a bounds check, a loop to consume every `'a'` while incrementing the position variables [^2], and then a single check for '`b'`.
I operate on `file.data()` directly to match the behaviour in `bar()` which uses `file`'s `char*`.

{% highlight cpp %}
void Lex::foo() {
    if (i >= file.size()) {
        return;
    }

    while (file.data()[i] == 'a') {
        i++;
        i_offset++;
    }

    if (file.data()[i] == 'b') {
        i_offset++;
    }

    return;
}
{% endhighlight %}

`bar` has the same functionality but we use local copies of the class members.

{% highlight cpp %}
void Lex::bar() {
    auto fp{file.data()};
    auto sz{file.size()};
    auto ii{i};
    auto ii_offset{i_offset};

    if (ii >= sz) {
        return;
    }

    while (fp[ii] == 'a') {
        ii++;
        ii_offset++;
    }

    if (fp[ii] == 'b') {
        ii_offset++;
    }

    i = ii;
    i_offset = ii_offset;

    return;
}
{% endhighlight %}

# `foo()` optimised assembly

We begin with the file bounds check.
The `char*` is then in `rcx` and the first `'a'` check if performed.
Simple enough so far.

{% highlight nasm %}
__xmm@00000000000000010000000000000001 DB 01H, 00H, 00H, 00H, 00H, 00H, 00H
        DB      00H, 01H, 00H, 00H, 00H, 00H, 00H, 00H, 00H

this$ = 8
void Lex::foo(void) PROC                              ; Lex::foo, COMDAT
        mov     rax, QWORD PTR [rcx+16]        ; rax = this->i
        cmp     rax, QWORD PTR [rcx+8]         ; this->i - file.size()
        jae     SHORT $LN5@foo                 ; if (>0) goto LN5
        mov     rdx, QWORD PTR [rcx]           ; rdx = file.data()
        cmp     BYTE PTR [rdx+rax], 97         ; file[i] - 'a'
        jne     SHORT $LN3@foo                 ; if (!0) goto LN3
{% endhighlight %}

`i` and `i_offset` are loaded together into the 128 bit `xmm1` register and incremented in parallel.
For every loop iteration, memory is accesses three times to update the instance members, load `i` from the class, and get the current character.

{% highlight nasm %}
        movdqa  xmm2, XMMWORD PTR __xmm@00000000000000010000000000000001 ; xmm2 = {64'b1, 64'b1}
        movdqu  xmm1, XMMWORD PTR [rcx+16]     ; xmm1 = {i, i_offset}
$LL2@foo:                                      ;
        movdqa  xmm0, xmm2                     ; xmm0 = {64'b1, 64'b1}
        paddq   xmm0, xmm1                     ; {i++, i_offset++}
        movdqu  XMMWORD PTR [rcx+16], xmm0     ; Update this->i and this->i_offset
        mov     rax, QWORD PTR [rcx+16]        ; rax = this->i
        movdqa  xmm1, xmm0                     ; xmm1 = {i, i_offset}
        cmp     BYTE PTR [rax+rdx], 97         ; file[i] - 'a'
        je      SHORT $LL2@foo                 ; if (0) goto LL2
{% endhighlight %}

Finally we do the check for `'b'` and return.

{% highlight nasm %}
$LN3@foo:                                      ;
        cmp     BYTE PTR [rdx+rax], 98         ; file[i] - 'b'
        jne     SHORT $LN5@foo                 ; if (!0) goto LN5
        inc     QWORD PTR [rcx+24]             ; i_offset++
$LN5@foo:                                      ;
        ret     0                              ;
void Lex::foo(void) ENDP                              ; Lex::foo
{% endhighlight %}

# `bar()` optimised assembly

The members are loaded into registers and the first `'a'` check is performed.
With four memory reads, `bar` will be slightly slower to start than `foo`.

{% highlight nasm %}
this$ = 8
void Lex::bar(void) PROC                              ; Lex::bar, COMDAT
        mov     r8, rcx                   ; r8 = this
        mov     rcx, QWORD PTR [rcx]      ; rcx = fp = file.data()
        mov     rax, QWORD PTR [r8+16]    ; rax = ii = i
        mov     rdx, QWORD PTR [r8+24]    ; rdx = ii_offset = i_offset
        cmp     rax, QWORD PTR [r8+8]     ; ii - sz
        jae     SHORT $LN1@bar            ; if (>0) goto LN1
        cmp     BYTE PTR [rax+rcx], 97    ; fp[ii] == "a"
        jne     SHORT $LN3@bar            ; if (!0) goto LN3
        npad    6                         ;
{% endhighlight %}

Each loop iteration has a single memory access in contrast to `bar`'s three because `i` and `i_offset` are in registers.

{% highlight nasm %}
$LL2@bar:                                 ;
        inc     rax                       ; ii++
        inc     rdx                       ; ii_offset++
        cmp     BYTE PTR [rcx+rax], 97    ; if (fp[ii] == 'a')    
        je      SHORT $LL2@bar            ; goto LL2
{% endhighlight %}

We update the class members before returning.

{% highlight nasm %}
$LN3@bar:                                 ;
        movzx   ecx, BYTE PTR [rax+rcx]   ; ecx = fp[ii]
        mov     QWORD PTR [r8+16], rax    ; this->i = ii
        cmp     cl, 98                    ; fp[ii] - 'b'
        lea     rax, QWORD PTR [rdx+1]    ; rax = ii_offset + 1
        cmovne  rax, rdx                  ; if (!0) rax = ii_offset (the value without incrementing)
        mov     QWORD PTR [r8+24], rax    ; this->i_offset = i_offset
$LN1@bar:                                 ;
        ret     0                         ;
void Lex::bar(void) ENDP                              ; Lex::bar
{% endhighlight %}

If the `'a'` checking loop lasts for more than a few cycles, `bar` will be faster than `foo` due to its single memory access vs `foo`'s three.

[^1]: <https://godbolt.org/z/75f1j3n5h>
[^2]: I'm aware incrementing both the index and offset makes no sense.