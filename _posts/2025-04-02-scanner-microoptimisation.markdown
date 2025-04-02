---
layout: post
title:  "C++ Micro-optimisation: Scanner"
date:   2025-03-31 19:10:38 +0100
categories: assembly cpp
---

I'll cover a micro-optimisation I did on my compiler's scanner today.
This is with MSVC and `-O2`.

{% highlight cpp %}
auto Scanner::at_end() const noexcept -> bool {
    return (i + i_offset) >= file_size;
}
auto Scanner::current() const noexcept -> char {
    return at_end() ? '\0' : file[i + i_offset];
}
{% endhighlight %}

The first function signals if we've reached the end of the file.
The second function returns the current character.

{% highlight nasm %}
?at_end@Scanner@pequod@@QEBA_NXZ PROC			; pequod::Scanner::at_end, COMDAT
; 567  :     return (i + i_offset) >= file_size;
	mov	rax, QWORD PTR [rcx+8]
	add	rax, QWORD PTR [rcx]
	cmp	rax, QWORD PTR [rcx+32]
	setae	al
	ret	0
?at_end@Scanner@pequod@@QEBA_NXZ ENDP			; pequod::Scanner::at_end

this$ = 8
?current@Scanner@pequod@@QEBADXZ PROC			; pequod::Scanner::current, COMDAT
; 567  :     return (i + i_offset) >= file_size;
	mov	rdx, QWORD PTR [rcx+8]
	mov	r8, QWORD PTR [rcx]
	lea	rax, QWORD PTR [r8+rdx]
	cmp	rax, QWORD PTR [rcx+32]
; 570  :     return at_end() ? '\0' : file[i + i_offset];
	jb	SHORT $LN3@current
	xor	al, al
	ret	0
$LN3@current:
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1470 :         return _Mydata[_Off];
	mov	rcx, QWORD PTR [rcx+16]
	add	rcx, r8
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 570  :     return at_end() ? '\0' : file[i + i_offset];
	movzx	eax, BYTE PTR [rcx+rdx]
	ret	0
?current@Scanner@pequod@@QEBADXZ ENDP			; pequod::Scanner::current
{% endhighlight %}

Here is the optimised version.

{% highlight cpp %}
auto Scanner::get_idx() const noexcept -> std::size_t {
    return (i + i_offset);
}
auto Scanner::at_end() const noexcept -> bool {
    return get_idx() >= file_size;
}
auto Scanner::current() const noexcept -> char {
    auto idx{get_idx()};
    return (idx >= file_size) ? '\0' : file[idx];
}
{% endhighlight %}

We calculate the current index as a local variable and do the bounds check manually.

{% highlight nasm %}
this$ = 8
?get_idx@Scanner@pequod@@QEBA_KXZ PROC			; pequod::Scanner::get_idx, COMDAT
; 567  :     return (i + i_offset);
	mov	rax, QWORD PTR [rcx+8]
	add	rax, QWORD PTR [rcx]
	ret	0
?get_idx@Scanner@pequod@@QEBA_KXZ ENDP			; pequod::Scanner::get_idx

this$ = 8
?at_end@Scanner@pequod@@QEBA_NXZ PROC			; pequod::Scanner::at_end, COMDAT
; 567  :     return (i + i_offset);
	mov	rax, QWORD PTR [rcx+8]
	add	rax, QWORD PTR [rcx]
; 570  :     return get_idx() >= file_size;
	cmp	rax, QWORD PTR [rcx+32]
	setae	al
	ret	0
?at_end@Scanner@pequod@@QEBA_NXZ ENDP			; pequod::Scanner::at_end

this$ = 8
?current@Scanner@pequod@@QEBADXZ PROC			; pequod::Scanner::current, COMDAT
; 567  :     return (i + i_offset);
	mov	rdx, QWORD PTR [rcx+8]
	add	rdx, QWORD PTR [rcx]
; 573  :     auto idx{get_idx()};
; 574  :     return (idx >= file_size) ? '\0' : file[idx];
	cmp	rdx, QWORD PTR [rcx+32]
	jb	SHORT $LN3@current
	xor	al, al
	ret	0
$LN3@current:
; 573  :     auto idx{get_idx()};
; 574  :     return (idx >= file_size) ? '\0' : file[idx];
	mov	rax, QWORD PTR [rcx+16]
	movzx	eax, BYTE PTR [rdx+rax]
	ret	0
?current@Scanner@pequod@@QEBADXZ ENDP			; pequod::Scanner::current
{% endhighlight %}

With this change, `at_end` has gone from 11 to 9 instructions.
A whopping improvement.