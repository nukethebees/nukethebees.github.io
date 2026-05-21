---
layout: post
title:  "Annotated assembly of an AVX-512 byte summing loop"
date:   2026-05-21 22:27:00 +0100
categories: software cpp asm
---

This post contains annotated assembly for the following C++ code:

```c++
#include <cstdint>
#include <cstddef>

void add_values_0_restrict(std::uint8_t const* __restrict a, 
                           std::uint8_t const* __restrict b, 
                           std::uint8_t* __restrict c, 
                           std::size_t n) {
    for (std::size_t i{0}; i < n; ++i) {
        c[i] = a[i] + b[i];
    }
}
```

The goal was to generate AVX 512 intrinsics and to analyse the resulting assembly. It was [compiled on Godbolt](https://godbolt.org/z/88sYP93Ks) using the `x86-64 clang 22.1.0` compiler.

Flags:

* `-std=c++23`
* `-O2`
* `-mavx512bw`
* `-mavx512vl`
* `-masm=intel`
* `-fverbose-asm`

With the [Linux x86-64 calling convention](https://www.ired.team/miscellaneous-reversing-forensics/windows-kernel-internals/linux-x64-calling-convention-stack-frame), the arguments are assigned to the following registers:

* `rdi = a`
* `rsi = b`
* `rdx = c`
* `rcx = n`

Notation used:

* Bit slice: `[MSB:LSB]`
* Byte range: `[start:end)`

```nasm
        test    rcx, rcx                                   ; n == 0?
        je      .LBB0_13                                   ; goto end
        cmp     rcx, 16                                    ; compare(n, 16)
        jae     .LBB0_4                                    ; jump if (n >= 16)
        xor     eax, eax                                   ; 
        jmp     .LBB0_3                                    ; 
.LBB0_4:                                                   ; 
        cmp     rcx, 256                                   ; compare(n, 256)
        jae     .LBB0_6                                    ; jump if (n >= 256)
        xor     eax, eax                                   ; Clear eax
        jmp     .LBB0_10                                   ; 
.LBB0_6:                                                   ; 
        mov     rax, rcx                                   ; rax = n
        and     rax, -256                                  ; [111...]0000_0000. 
                                                           ; Clear the low 8 bits
                                                           ; Effectively (n / 256) * 256
                                                           ; rax = n - (n % 256)
                                                           ; largest multiple of 256 <= n
        xor     r8d, r8d                                   ; clear r8d 
                                                           ; Clearing r8d clears r8 entirely
.LBB0_7:                                                   ; 
                                                           ; zmm0..zmm3 = b[r8:r8+256)
        vmovdqu64       zmm0, zmmword ptr [rsi + r8]       ; zmm0 = b[r8:r8 + 64)
        vmovdqu64       zmm1, zmmword ptr [rsi + r8 + 64]  ; zmm1 = b[r8 + 64:r8 + 128)
        vmovdqu64       zmm2, zmmword ptr [rsi + r8 + 128] ; zmm2 = b[r8 + 128:r8 + 192)
        vmovdqu64       zmm3, zmmword ptr [rsi + r8 + 192] ; zmm3 = b[r8 + 192:r8 + 256)
        vpaddb  zmm0, zmm0, zmmword ptr [rdi + r8]         ; zmm0..zmm3 += a[r8:r8 + 256)
        vpaddb  zmm1, zmm1, zmmword ptr [rdi + r8 + 64]    ; 
        vpaddb  zmm2, zmm2, zmmword ptr [rdi + r8 + 128]   ; 
        vpaddb  zmm3, zmm3, zmmword ptr [rdi + r8 + 192]   ; 
        vmovdqu64       zmmword ptr [rdx + r8], zmm0       ; c[r8:r8 + 256) = zmm0..zmm3
        vmovdqu64       zmmword ptr [rdx + r8 + 64], zmm1  ; 
        vmovdqu64       zmmword ptr [rdx + r8 + 128], zmm2 ; 
        vmovdqu64       zmmword ptr [rdx + r8 + 192], zmm3 ; 
        add     r8, 256                                    ; r8 += 256
        cmp     rax, r8                                    ; compare(rax, r8).
                                                           ; Processed all 256 byte chunks?
        jne     .LBB0_7                                    ; iterate if (rax != r8)
        cmp     rcx, rax                                   ; check if (bytes_written == n)
        je      .LBB0_13                                   ; return if (bytes_written == n)
        test    cl, -16                                    ; cl = low byte of n
                                                           ; n[7:0] & 0b1111_0000
        je      .LBB0_3                                    ; jump if zero flag set
                                                           ; jump if (n[7:0] < 16)
                                                           ; i.e. jump if no 16 byte chunks left
.LBB0_10:                                                  ; 
        mov     r8, rax                                    ; r8 = rax
        mov     rax, rcx                                   ; rax = n
        and     rax, -16                                   ; rax = n & [1111...]_0000
.LBB0_11:                                                  ; 
        vmovdqu xmm0, xmmword ptr [rsi + r8]               ; xmm0 = b[r8:r8+16)
        vpaddb  xmm0, xmm0, xmmword ptr [rdi + r8]         ; xmm0 += a[r8:r8+16)
        vmovdqu xmmword ptr [rdx + r8], xmm0               ; c[r8:r8+16) = xmm0
        add     r8, 16                                     ; r8 += 16
        cmp     rax, r8                                    ; r8 == rax?
                                                           ; The previous low byte & -16 check
                                                           ; combined with the -256 loop means 
                                                           ; we're checking if n[7:4] != 0
                                                           ; n[8] and above is already done
        jne     .LBB0_11                                   ; Iterate again if (r8 != rax)
        jmp     .LBB0_12                                   ; Jump
.LBB0_3:                                                   ; rax acts as an offset
                                                           ; if coming from the big loop
                                                           ; you'll have computed 
                                                           ; 256*x bytes already
        movzx   r8d, byte ptr [rsi + rax]                  ; r8[7:0] = b[rax] 
                                                           ; (zero extend the rest of r8)
        add     r8b, byte ptr [rdi + rax]                  ; r8[7:0] += a[rax]
        mov     byte ptr [rdx + rax], r8b                  ; c[rax] = r8[7:0]
        inc     rax                                        ; rax++
.LBB0_12:                                                  ; 
        cmp     rcx, rax                                   ; 
        jne     .LBB0_3                                    ; iterate if (rax != n)
.LBB0_13:                                                  ; 
        vzeroupper                                         ; avoid AVX/SSE transition 
                                                           ; penalties before returning
        ret                                                ; 
```