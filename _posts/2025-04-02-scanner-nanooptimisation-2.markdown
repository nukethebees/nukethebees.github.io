---
layout: post
title:  "C++ Nano-optimisation 2: Scanner string function"
date:   2025-04-02 19:10:38 +0100
categories: assembly cpp
---

I'll cover a second nano-optimisation I did on my compiler's scanner today.
This is with MSVC and `-O2`.

I merged some conditionals into a larger switch statement.

{% highlight cpp %}
auto Scanner::string() -> SourceToken {
    while (!at_end() && peek() != '"') {
        if (peek() == '\\') {
            i_offset++;
            // Check for escaped double-quotes
            if (peek() == '"') {
                i_offset++;
            }
        } else {
            i_offset++;
        }
    }

    if (at_end()) {
        return make_valueless_token(TokenType::END_OF_FILE);
    }

    // Consume the other double quote
    i_offset++;

    auto const str{get_lexeme()};
    auto const without_quotes{str.substr(1, str.size() - 2)};
    return make_value_token(TokenType::STRING, without_quotes, without_quotes);
}
{% endhighlight %}

The loop begins when we found a `"` before calling `string()`.
The functions loops through each character in the input buffer until it finds the second `"` or we reach the end of the file (EOF).
If a `\` is found, we check if it's an escaped `"`. 
Without this conditional, the loop would end prematurely on the next iteration.

We then handle the EOF case or return a token containing our string.

<details>
<summary>
<b>Assembly code output</b>
</summary>

{% highlight nasm linenos %}
$T1 = 32
this$ = 80
__$ReturnUdt$ = 88
?string@Scanner@pequod@@QEAA?AUSourceToken@2@XZ PROC	; pequod::Scanner::string, COMDAT
; 831  : auto Scanner::string() -> SourceToken {
$LN197:
	push	rbx
	sub	rsp, 64					; 00000040H
; 567  :     return (i + i_offset) >= file_size;
	mov	rax, QWORD PTR [rcx+8]
; 831  : auto Scanner::string() -> SourceToken {
	mov	rbx, rdx
; 567  :     return (i + i_offset) >= file_size;
	mov	r10, QWORD PTR [rcx]
; 831  : auto Scanner::string() -> SourceToken {
	mov	r9, rcx
; 567  :     return (i + i_offset) >= file_size;
	mov	r11, QWORD PTR [rcx+32]
	lea	r8, QWORD PTR [r10+rax]
	cmp	r8, r11
; 832  :     while (!at_end() && peek() != '"') {
	jae	SHORT $LN181@string
$LL2@string:
; 590  :     auto const index{i + i_offset + n};
	lea	rdx, QWORD PTR [r10+1]
	add	rdx, rax
; 591  :     return (index < file_size) ? file[index] : '\0';
	cmp	rdx, r11
	jae	SHORT $LN28@string
	mov	rcx, QWORD PTR [r9+16]
; 832  :     while (!at_end() && peek() != '"') {
	cmp	BYTE PTR [rdx+rcx], 34			; 00000022H
	je	SHORT $LN181@string
; 591  :     return (index < file_size) ? file[index] : '\0';
	movzx	ecx, BYTE PTR [rdx+rcx]
; 833  :         if (peek() == '\\') {
	inc	rax
	mov	QWORD PTR [r9+8], rax
	cmp	cl, 92					; 0000005cH
	jne	SHORT $LN4@string
; 590  :     auto const index{i + i_offset + n};
	lea	rdx, QWORD PTR [r10+1]
	add	rdx, rax
; 591  :     return (index < file_size) ? file[index] : '\0';
	cmp	rdx, r11
	jae	SHORT $LN4@string
	mov	rcx, QWORD PTR [r9+16]
; 834  :             i_offset++;
; 835  :             // Check for escaped double-quotes
; 836  :             if (peek() == '"') {
	cmp	BYTE PTR [rdx+rcx], 34			; 00000022H
	jne	SHORT $LN4@string
; 837  :                 i_offset++;
	inc	rax
	jmp	SHORT $LN193@string
$LN28@string:
; 591  :     return (index < file_size) ? file[index] : '\0';
	inc	rax
$LN193@string:
; 567  :     return (i + i_offset) >= file_size;
	mov	QWORD PTR [r9+8], rax
$LN4@string:
	lea	rcx, QWORD PTR [r10+rax]
	cmp	rcx, r11
; 832  :     while (!at_end() && peek() != '"') {
	jb	SHORT $LL2@string
$LN181@string:
; 567  :     return (i + i_offset) >= file_size;
	lea	rcx, QWORD PTR [r10+rax]
	lea	rdx, QWORD PTR [rax+1]
	cmp	rcx, r11
; 838  :             }
; 839  :         } else {
; 840  :             i_offset++;
; 841  :         }
; 842  :     }
; 843  : 
; 844  :     if (at_end()) {
	jb	SHORT $LN7@string
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1761 :         if (_Mysize < _Off) {
	mov	r8, QWORD PTR [r9+24]
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 613  :     auto tkn{SourceToken(type, get_lexeme(), static_cast<uint32_t>(i))};
	mov	r11d, DWORD PTR [r9]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1761 :         if (_Mysize < _Off) {
	cmp	r8, r10
	jb	$LN178@string
; 1537 :         return basic_string_view(_Mydata + _Off, _Count);
	mov	rcx, QWORD PTR [r9+16]
; 1775 :         return (_STD min)(_Size, _Mysize - _Off);
	sub	r8, r10
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 759  :           _Which{static_cast<_Index_t>(_Idx)} { // initialize alternative _Idx from _Args...
	mov	BYTE PTR [rbx+16], 0
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1537 :         return basic_string_view(_Mydata + _Off, _Count);
	add	rcx, r10
; File C:\Users\matth\source\repos\Pequod\Pequod\source_token.cpp
; 13   :     : lexeme{lexeme}
	mov	QWORD PTR [rbx+24], rcx
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1369 :         : _Mydata(_Cts), _Mysize(_Count) {
	cmp	r8, rdx
	cmovb	rdx, r8
; File C:\Users\matth\source\repos\Pequod\Pequod\source_token.cpp
; 13   :     : lexeme{lexeme}
	mov	QWORD PTR [rbx+32], rdx
; 14   :     , type{type}
	mov	WORD PTR [rbx+40], 119			; 00000077H
; 15   :     , position{position} {}
	mov	DWORD PTR [rbx+44], r11d
$LN194@string:
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 854  : }
	mov	rax, QWORD PTR [r9+8]
	inc	rax
	mov	QWORD PTR [r9+8], 0
	add	QWORD PTR [r9], rax
	mov	rax, rbx
	add	rsp, 64					; 00000040H
	pop	rbx
	ret	0
$LN7@string:
; 845  :         return make_valueless_token(TokenType::END_OF_FILE);
; 846  :     }
; 847  : 
; 848  :     // Consume the other double quote
; 849  :     i_offset++;
	mov	QWORD PTR [r9+8], rdx
; 564  :     return file.substr(i, i_offset + 1);
	lea	r11, QWORD PTR [rdx+1]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1761 :         if (_Mysize < _Off) {
	mov	rcx, QWORD PTR [r9+24]
	cmp	rcx, r10
	jb	SHORT $LN178@string
; 1537 :         return basic_string_view(_Mydata + _Off, _Count);
	mov	rax, QWORD PTR [r9+16]
; 1775 :         return (_STD min)(_Size, _Mysize - _Off);
	sub	rcx, r10
; 1369 :         : _Mydata(_Cts), _Mysize(_Count) {
	cmp	rcx, r11
	cmovb	r11, rcx
	cmp	r11, 1
; 1761 :         if (_Mysize < _Off) {
	jb	SHORT $LN178@string
; 1369 :         : _Mydata(_Cts), _Mysize(_Count) {
	xor	edx, edx
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 759  :           _Which{static_cast<_Index_t>(_Idx)} { // initialize alternative _Idx from _Args...
	mov	BYTE PTR $T1[rsp+16], 4
; File C:\Users\matth\source\repos\Pequod\Pequod\source_token.cpp
; 8    :     : value{value}
	movsd	xmm1, QWORD PTR $T1[rsp+16]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1775 :         return (_STD min)(_Size, _Mysize - _Off);
	lea	r8, QWORD PTR [rax+1]
	add	r8, r10
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 852  :     auto const without_quotes{str.substr(1, str.size() - 2)};
	lea	rcx, QWORD PTR [r11-2]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 351  :         : _Head(static_cast<_Types&&>(_Args)...) {} // initialize _Head with _Args...
	mov	QWORD PTR $T1[rsp], r8
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1536 :         _Count = _Clamp_suffix_size(_Off, _Count);
	lea	rax, QWORD PTR [r11-1]
; 1369 :         : _Mydata(_Cts), _Mysize(_Count) {
	cmp	rax, rcx
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 603  :     auto tkn{SourceToken(type, value, lexeme, static_cast<uint32_t>(i))};
	mov	eax, DWORD PTR [r9]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1369 :         : _Mydata(_Cts), _Mysize(_Count) {
	setb	dl
	lea	rcx, QWORD PTR [rdx-2]
	add	rcx, r11
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 351  :         : _Head(static_cast<_Types&&>(_Args)...) {} // initialize _Head with _Args...
	mov	QWORD PTR $T1[rsp+8], rcx
; File C:\Users\matth\source\repos\Pequod\Pequod\source_token.cpp
; 8    :     : value{value}
	movups	xmm0, XMMWORD PTR $T1[rsp]
	movups	XMMWORD PTR [rbx], xmm0
	movsd	QWORD PTR [rbx+16], xmm1
; 9    :     , lexeme{lexeme}
	mov	QWORD PTR [rbx+24], r8
	mov	QWORD PTR [rbx+32], rcx
; 10   :     , type{type}
	mov	WORD PTR [rbx+40], 68			; 00000044H
; 11   :     , position{position} {}
	mov	DWORD PTR [rbx+44], eax
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 853  :     return make_value_token(TokenType::STRING, without_quotes, without_quotes);
	jmp	$LN194@string
$LN178@string:
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1762 :             _Xran();
	call	?_Xran@?$basic_string_view@DU?$char_traits@D@std@@@std@@CAXXZ ; std::basic_string_view<char,std::char_traits<char> >::_Xran
	int	3
$LN192@string:
?string@Scanner@pequod@@QEAA?AUSourceToken@2@XZ ENDP	; pequod::Scanner::string
{% endhighlight %}

</details>

<br>

And now the optimised version.

{% highlight cpp %}
auto Scanner::string() -> SourceToken {
    while (true) {
        switch (peek()) {
            case '\\': {
                i_offset++;
                // Check for escaped double-quotes
                if (peek() == '"') {
                    i_offset++;
                }
                break;
            }
            case '"': {
                i_offset++;
                goto loop_end;
            }
            case '\0': {
                return make_valueless_token(TokenType::END_OF_FILE);
            }
            default: {
                i_offset++;
                break;
            }
        }
    }

loop_end:
    // Offset to remove quote characters
    auto const without_quotes{this->file.substr(i + 1, i_offset - 1)};
    return make_value_token(TokenType::STRING, without_quotes, without_quotes);
}
{% endhighlight %}

There's no need to check for the end of file as we'll only peek one character ahead at a time so the null terminator can be handled by our new switch statement.
We now only have two levels of conditional branching whereas before we had three.
We've also folded the return statement for the EOF case into the branch directly.

Finally we calculate the indices for our `std::string_view` lexeme directly instead of creating a `string_view` then creating a second one to trim off the double-quote characters.

<details>
<summary>
<b>Assembly code output</b>
</summary>
{% highlight nasm linenos %}
$T1 = 32
this$ = 80
__$ReturnUdt$ = 88
?string@Scanner@pequod@@QEAA?AUSourceToken@2@XZ PROC	; pequod::Scanner::string, COMDAT

; 835  : auto Scanner::string() -> SourceToken {
$LN110:
	push	rbx
	sub	rsp, 64					; 00000040H
; 594  :     auto const index{i + i_offset + n};
	mov	r10, QWORD PTR [rcx]
; 835  : auto Scanner::string() -> SourceToken {
	mov	rbx, rdx
; 595  :     return (index < file_size) ? file[index] : '\0';
	mov	r11, QWORD PTR [rcx+32]
$LL2@string:
; 590  : auto Scanner::peek() const noexcept -> char {
; 591  :     return peek(1);
; 592  : }
; 593  : auto Scanner::peek(std::size_t n) const noexcept -> char {
; 594  :     auto const index{i + i_offset + n};
	mov	r9, QWORD PTR [rcx+8]
	lea	r8, QWORD PTR [r9+1]
	add	r8, r10
; 595  :     return (index < file_size) ? file[index] : '\0';
	cmp	r8, r11
	jae	$LN10@string
	mov	rax, QWORD PTR [rcx+16]
	movzx	r8d, BYTE PTR [r8+rax]
; 836  :     while (true) {
; 837  :         switch (peek()) {
	test	r8b, r8b
	je	$LN10@string
	lea	rdx, QWORD PTR [r9+1]
	mov	QWORD PTR [rcx+8], rdx
	cmp	r8b, 34					; 00000022H
	je	SHORT $LN8@string
	cmp	r8b, 92					; 0000005cH
	jne	SHORT $LL2@string
; 594  :     auto const index{i + i_offset + n};
	lea	r8, QWORD PTR [r10+1]
	add	r8, rdx
; 595  :     return (index < file_size) ? file[index] : '\0';
	cmp	r8, r11
	jae	SHORT $LL2@string
; 838  :             case '\\': {
; 839  :                 i_offset++;
; 840  :                 // Check for escaped double-quotes
; 841  :                 if (peek() == '"') {
	cmp	BYTE PTR [r8+rax], 34			; 00000022H
	jne	SHORT $LL2@string
; 842  :                     i_offset++;
	lea	rax, QWORD PTR [rdx+1]
	mov	QWORD PTR [rcx+8], rax
; 852  :             }
; 853  :             default: {
; 854  :                 i_offset++;
; 855  :                 break;
; 856  :             }
; 857  :         }
; 858  :     }
	jmp	SHORT $LL2@string
$LN8@string:
$loop_end$111:
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1761 :         if (_Mysize < _Off) {
	mov	r8, QWORD PTR [rcx+24]
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 862  :     auto const without_quotes{this->file.substr(i + 1, i_offset - 1)};
	lea	rdx, QWORD PTR [r10+1]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1761 :         if (_Mysize < _Off) {
	cmp	r8, rdx
	jb	SHORT $LN108@string
; 1775 :         return (_STD min)(_Size, _Mysize - _Off);
	sub	r8, rdx
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 759  :           _Which{static_cast<_Index_t>(_Idx)} { // initialize alternative _Idx from _Args...
	mov	BYTE PTR $T1[rsp+16], 4
; File C:\Users\matth\source\repos\Pequod\Pequod\source_token.cpp
; 8    :     : value{value}
	movsd	xmm1, QWORD PTR $T1[rsp+16]
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1537 :         return basic_string_view(_Mydata + _Off, _Count);
	add	rdx, rax
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 351  :         : _Head(static_cast<_Types&&>(_Args)...) {} // initialize _Head with _Args...
	mov	QWORD PTR $T1[rsp], rdx
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1369 :         : _Mydata(_Cts), _Mysize(_Count) {
	cmp	r8, r9
	cmovb	r9, r8
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\variant
; 351  :         : _Head(static_cast<_Types&&>(_Args)...) {} // initialize _Head with _Args...
	mov	QWORD PTR $T1[rsp+8], r9
; File C:\Users\matth\source\repos\Pequod\Pequod\source_token.cpp
; 8    :     : value{value}
	movups	xmm0, XMMWORD PTR $T1[rsp]
	movups	XMMWORD PTR [rbx], xmm0
	movsd	QWORD PTR [rbx+16], xmm1
; 9    :     , lexeme{lexeme}
	mov	QWORD PTR [rbx+24], rdx
	mov	QWORD PTR [rbx+32], r9
; 10   :     , type{type}
	mov	WORD PTR [rbx+40], 68			; 00000044H
; 11   :     , position{position} {}
	mov	DWORD PTR [rbx+44], r10d
; File C:\Users\matth\source\repos\Pequod\Pequod\scanner.cpp
; 578  :     i += i_offset + 1;
	mov	rax, QWORD PTR [rcx+8]
	inc	rax
; 579  :     i_offset = 0;
	mov	QWORD PTR [rcx+8], 0
	add	QWORD PTR [rcx], rax
; 864  : }
	mov	rax, rbx
	add	rsp, 64					; 00000040H
	pop	rbx
	ret	0
$LN10@string:
; 843  :                 }
; 844  :                 break;
; 845  :             }
; 846  :             case '"': {
; 847  :                 i_offset++;
; 848  :                 goto loop_end;
; 849  :             }
; 850  :             case '\0': {
; 851  :                 return make_valueless_token(TokenType::END_OF_FILE);
	mov	r8d, 119				; 00000077H
	mov	rdx, rbx
	call	?make_valueless_token@Scanner@pequod@@QEAA?AUSourceToken@2@W4TokenType@2@@Z ; pequod::Scanner::make_valueless_token
; 864  : }
	mov	rax, rbx
	add	rsp, 64					; 00000040H
	pop	rbx
	ret	0
$LN108@string:
; File C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include\__msvc_string_view.hpp
; 1762 :             _Xran();
	call	?_Xran@?$basic_string_view@DU?$char_traits@D@std@@@std@@CAXXZ ; std::basic_string_view<char,std::char_traits<char> >::_Xran
	int	3
$LN105@string:
?string@Scanner@pequod@@QEAA?AUSourceToken@2@XZ ENDP	; pequod::Scanner::string
{% endhighlight %}
</details>

<br>

Each instruction line generated by MSVC begins with a `\t` character so we can use that to get a good estimate of the reduction in instructions.
We've reduced the function from 97 to 65 instructions, a 33% reduction.
This could potentially be simplified further by not checking for `"` after `\` and instead incrementing the offset twice.