---
layout: post
title:  "C++ Assembly Differences with deducing this"
date:   2025-03-31 19:10:38 +0100
categories: assembly cpp
---

I recently discovered that MSVC gives slightly different assembly when using `deducing this` instead of the implicit `this` pointer.

The following function is the string scanning function from my compiler's scanner.
The function loops until it finds the second `"` or it reaches the end of the file.
Escape characters are ignored.

{% highlight cpp %}
auto Scanner::string() -> SourceToken {
    while (true) {
        switch (peek()) {
            case '\\': {
                i_offset += 2;
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

With C++23's `deducing this` feature, we can also explicitly list the class instance as an object parameter.
The fragment below illustrates this.

{% highlight cpp %}
auto Scanner::string(this Scanner& self) -> SourceToken {
    while (true) {
        switch (self.peek()) {
}
{% endhighlight %}

Here is MSVC's output with `*this`.
I'm only showing the instructions in the main loop for brevity.

{% highlight nasm %}
; 835  : auto Scanner::string() -> SourceToken {
$LN110:
    push    rbx
    sub     rsp, 64                 ; Initialise the stack
    mov     r10, QWORD PTR [rcx]    ; r10 = this->i
    mov     rbx, rdx                ; 
    mov     r11, QWORD PTR [rcx+32] ; r11 = this->file_size

$LL2@string:                        ; Start of while loop
                                    ; [Peek the next char]
    mov     r9, QWORD PTR [rcx+8]   ; r9 = this->i_offset
    lea     r8, QWORD PTR [r9+1]    ; i_offset++
    add     r8, r10                 ; r8 = (i_offset + 1) + i
    cmp     r8, r11                 ; Check if EOF
    jae     $LN10@string            ; goto EOF handler

    mov     rax, QWORD PTR [rcx+16] ; rax = this->file.data_
    movzx   r8d, BYTE PTR [r8+rax]  ; r8d = this->file[i + i_offset + 1]
    test    r8b, r8b                ; c == \0
    je      $LN10@string            ; goto EOF handler

    lea     rdx, QWORD PTR [r9+1]   ; rdx = i_offset+1
    mov     QWORD PTR [rcx+8], rdx  ; Update this->i_offset
    cmp     r8b, 34                 ; Check "
    je      SHORT $LN8@string       ; goto " handler

    cmp     r8b, 92                 ; Check \ 
    jne     SHORT $LL2@string       ; Restart loop if c != \ 

                                    ; \ Handler
    lea     r8, QWORD PTR [r10+1]   ; r8 = i+1
    add     r8, rdx                 ; r8 = i + i_offset + 2
    cmp     r8, r11                 ; Check if EOF
    jae     SHORT $LL2@string       ; Next iter if !EOF

    cmp     BYTE PTR [r8+rax], 34   ; Check "
    jne     SHORT $LL2@string       ; Next iter if !"

    lea     rax, QWORD PTR [rdx+1]  ; i_offset++
    mov     QWORD PTR [rcx+8], rax  ; Update this->i_offset
    jmp     SHORT $LL2@string       ; Next iter

$LN8@string:
$loop_end$111:
{% endhighlight %}

The output with `self`.

{% highlight nasm %}
; 835  : auto Scanner::string(this Scanner& self) -> SourceToken {
$LN96:
    push    rbx
    sub     rsp, 64                 ; Initialise the stack
    mov     r9, QWORD PTR [rdx]     ; r9 = i
    mov     rax, rdx                ; rax = &self
    mov     r10, QWORD PTR [rdx+32] ; r10 = self.file_size
    mov     rbx, rcx                ; ???
    npad    13

$LL2@string:                        ; Start of loop
                                    ; [Peek the next char]
    mov     r8, QWORD PTR [rax+8]   ; r8 = self.i_offset
    lea     rdx, QWORD PTR [r9+1]   ; rdx = i + 1
    add     rdx, r8                 ; rdx = i_offset + (i + 1)
    cmp     rdx, r10                ; Check EOF
    jae     $LN9@string             ; goto EOF handler

    mov     rcx, QWORD PTR [rax+16] ; rcx = self.file.data_
    movzx   edx, BYTE PTR [rdx+rcx] ; edx = file[i_offset + i + 1]
    test    dl, dl                  ; rdx == \0
    je      $LN9@string             ; goto EOF handler

    cmp     dl, 34                  ; c == "
    je      SHORT $LN7@string       ; goto " handler

    cmp     dl, 92                  ; c == \ 
    je      SHORT $LN6@string       ; goto \ handler

    inc     r8                      ; i_offset++
    mov     QWORD PTR [rax+8], r8   ; Update self.i_offset
    jmp     SHORT $LL2@string       ; Next iter

$LN6@string:                        ; Handle \ 
    add     r8, 2                   ; i_offset += 2
    mov     QWORD PTR [rax+8], r8   ; Update self.i_offset
    jmp     SHORT $LL2@string       ; Next iter

$LN7@string:                        ; Handle "
    lea     rcx, QWORD PTR [r8+1]   ; rcx = i_offset + 1
    mov     QWORD PTR [rax+8], rcx  ; Update self.i_offset

$loop_end$97:                       ; End of the loop
{% endhighlight %}

The output with `self` seems easier to follow.
It doesn't check for `"` twice and the jumps are more logical e.g. go to the `\` handling block immediately after checking that the character is a `\`.