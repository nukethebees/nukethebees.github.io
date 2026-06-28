---
layout: post
title:  "Comparing an Integer Division Optimisation in Clang, MSVC, and GCC"
date:   2026-06-28 23:00:00 +0100
categories: software cpp asm
---

This post compares how Clang, MSVC, and GCC optimise a small integer division routine.

I was optimising the conversion of a 1D index into a 3D row-major grid coordinate and implemented two versions using:

1. operators `/` and `%`
2. `std::div`

Neither implementation was fully optimal on Clang, MSVC, and GCC.
The code below was compiled on Compiler Explorer ([available here](https://godbolt.org/z/74f3Kaeq8)).

# Grid Coordinate Function

The pseudocode below shows how to convert a 1D index into a 3D row-major grid coordinate:

```
x = i / grid.y / grid.z
y = (i / grid.z) % grid.y
z = i % grid.z
```

An optimal x86 implementation should only require two [`idiv` instructions](https://www.felixcloutier.com/x86/idiv) as it calculates the quotient and remainder in a single instruction and stores them in `rax` and `rdx` respectively.

The expanded pseudocode below shows this:

```
i / grid.z -> (quot_z, rem_z)
quot_z / grid.y -> (quot_yz, rem_yz)

x = quot_yz
y = rem_yz
z = rem_z
```

# Implementation with operators

This implementation uses the division and modulo operators.
The function parameters are assumed to be `>= 0`.

```c++
#include <cstdint>
#include <cstdlib>

struct Coord {
    std::int32_t x;
    std::int32_t y;
    std::int32_t z;
};

auto get_grid_coordinate(std::int32_t const grid_y,
                         std::int32_t const grid_z,
                         std::int32_t const i) -> Coord {
    auto const quot_z{i / grid_z};
    auto const rem_z{i % grid_z};

    auto const quot_yz{quot_z / grid_y};
    auto const quot_z_rem_y{quot_z % grid_y};

    return {quot_yz, quot_z_rem_y, rem_z};
}
```

## Clang 

Clang creates an optimal implementation with only two `idiv` instructions.

```nasm
; return value = [edx, rax] 
               = [{z}, {y, x}]

; rdi = grid_y
; rsi = grid_z
; rdx = i

get_grid_coordinate(int, int, int):
  mov     eax, edx ; eax = i
  cdq              ; Sign extend eax
  idiv    esi      ; eax = i / grid_z = quot_z 
                   ; edx = i % grid_z = z
  mov     ecx, edx ; ecx = z
  cdq              ; Sign extend eax
  idiv    edi      ; eax = quot_z / grid_y = x
                   ; edx = quot_z % grid_y = y
  shl     rdx, 32  ; rdx = [y, 0]
  or      rax, rdx ; rax = [y, x]
  mov     edx, ecx ; edx = z
  ret              ;
```

## MSVC

MSVC misses an optimisation and uses three `idiv` instructions.
The second division is needlessly repeated when calculating `y`.

```nasm
; rcx = &(return value)
; rdx = grid_y
; r8 = grid_z
; r9 = i

__$ReturnAddress$ = 8
grid_y$ = 16
grid_z$ = 24
i$ = 32
Coord get_grid_coordinate(int,int,int) PROC            
  mov     r10d, edx              ; r10 = grid_y
  mov     eax, r9d               ; eax = i
  cdq                            ; Sign extend eax
  idiv    r8d                    ; eax = i / grid_z = quot_z
                                 ; edx = i % grid_z = z
  mov     r8d, eax               ; r8d = quot_z
  mov     r9d, edx               ; r9d = z
  cdq                            ; Sign extend eax
  mov     DWORD PTR [rcx+8], r9d ; out.z = z
  idiv    r10d                   ; eax = quot_z / grid_y = x
                                 ; edx = quot_z % grid_y = y
  mov     DWORD PTR [rcx], eax   ; out.x = x
  mov     eax, r8d               ; eax = quot_z
  cdq                            ; Sign extend eax
  idiv    r10d                   ; eax = quot_z / grid_y = x
                                 ; edx = quot_z % grid_y = y
  mov     rax, rcx               ; rax = &(return value)
  mov     DWORD PTR [rcx+4], edx ; out.y = y
  ret     0                      ;
Coord get_grid_coordinate(int,int,int) ENDP            
```

## GCC

GCC's implementation is similar to Clang's except it doesn't use `shl` to set up the return value and it temporarily spills `x` and `y` to the stack before packing them into `rax`.

```nasm
; return value = [edx, rax] 
               = [{z}, {y, x}]

; rdi = grid_y
; rsi = grid_z
; rdx = i

"get_grid_coordinate(int, int, int)":
  mov     eax, edx                 ; eax = i
  cdq                              ; Sign extend eax
  idiv    esi                      ; eax = i / grid_z = quot_z
                                   ; edx = i % grid_z = z
  mov     ecx, edx                 ; ecx = z
  cdq                              ; Sign extend eax
  idiv    edi                      ; eax = quot_z / grid_y = x
                                   ; edx = quot_z % grid_y = y
  mov     DWORD PTR [rsp-20], edx  ; [rsp-20] = y
  mov     rdx, rcx                 ; rdx = z
  mov     DWORD PTR [rsp-24], eax  ; [rsp-24] = x
  mov     rax, QWORD PTR [rsp-24]  ; rax = {y, x}
  ret                              ;
```

# Implementation with std::div

This implementation uses `std::div`.
I felt the explicitly returned quotient and remainder may have been easier for the compiler to optimise.

```c++
auto get_grid_coordinate_std(std::int32_t const grid_y,
                             std::int32_t const grid_z,
                             std::int32_t const i) -> Coord {
    auto const div_z{std::div(i, grid_z)};
    auto const div_yz{std::div(div_z.quot, grid_y)};

    return {div_yz.quot, div_yz.rem, div_z.rem};
}
```

## Clang

Clang doesn't inline `std::div`, resulting in two function calls.
This will likely perform worse due to the setup required for the function calls and the function call overhead.

The `push rax` instruction maintains a 16 byte stack pointer alignment[^1]. 

```nasm
; return value = [edx, rax] 
               = [{z}, {y, x}]

; rdi = grid_y
; rsi = grid_z
; rdx = i

get_grid_coordinate_std(int, int, int):
  push    r14        ; Save caller's r14
  push    rbx        ; Save caller's rbx
  push    rax        ; Alignment padding, not saving rax
  mov     ebx, edi   ; ebx = grid_y
  mov     edi, edx   ; edx = i
  call    div@PLT    ; std::div(i [rdi], grid_z [rsi])
                     ; rax low 32 = quot_z
                     ; rax high 32 = z
  mov     r14, rax   ; r14 = {z, quot_z}
  shr     r14, 32    ; r14 = z
  mov     edi, eax   ; edi = quot_z
  mov     esi, ebx   ; esi = grid_y
  call    div@PLT    ; std::div(quot_z [rdi], grid_y [rsi])
                     ; rax low 32 = x = out.x
                     ; rax high 32 = y = out.y
  mov     edx, r14d  ; edx = z
  add     rsp, 8     ; Discard alignment padding
  pop     rbx        ; Restore caller's r14 and rbx
  pop     r14        ;
  ret                ;
```

## MSVC

MSVC has inlined the calls, using only two `idiv` instructions unlike before.

```nasm
; rcx = &(return value)
; rdx = grid_y
; r8 = grid_z
; r9 = i

__$ReturnAddress$ = 8
grid_y$ = 16
grid_z$ = 24
i$ = 32
Coord get_grid_coordinate_std(int,int,int) PROC        
  mov     r10d, edx               ; r10 = grid_y
  mov     eax, r9d                ; eax = i
  cdq                             ; Sign extend eax
  idiv    r8d                     ; eax = i / grid_z = quot_z
                                  ; edx = i % grid_z = z
  mov     r8d, edx                ; r8d = z
  cdq                             ; Sign extend eax
  idiv    r10d                    ; eax = quot_z / grid_y = x
                                  ; edx = quot_z % grid_y = y
  mov     DWORD PTR [rcx+8], r8d  ; out.z = z
  mov     DWORD PTR [rcx], eax    ; out.x = x
  mov     rax, rcx                ; rax = &(return value) 
  mov     DWORD PTR [rcx+4], edx  ; out.y = y
  ret     0                       ;
Coord get_grid_coordinate_std(int,int,int) ENDP        
```

## GCC

GCC's solution is largely similar to Clang's.

```nasm
; return value = [edx, rax] 
               = [{z}, {y, x}]

; rdi = grid_y
; rsi = grid_z
; rdx = i

get_grid_coordinate_std(int, int, int):
  push    rbp       ; Store caller rbp
  mov     ebp, edi  ; ebp = grid_y
  mov     edi, edx  ; edi = i
  push    rbx       ; Store caller rbx
  sub     rsp, 40   ; Pad stack for 16 byte alignment
  call    "div"     ; div(i [rdi], grid_z [rsi])
                    ; rax low 32 = quot_z
                    ; rax high 32 = z
  mov     esi, ebp  ; esi = grid_y
  mov     rbx, rax  ; rbx = {z, quot_z}
  mov     edi, eax  ; edi = quot_z
  call    "div"     ; div(quot_z [rdi], grid_y [rsi])
                    ; rax low 32 = x = out.x
                    ; rax high 32 = y = out.y
  shr     rbx, 32   ; rbx = z
  add     rsp, 40   ; Restore stack pointer
  mov     rdx, rbx  ; rdx = z
  pop     rbx       ; Restore caller rbx
  pop     rbp       ; Restore caller rbp
  ret               ;
```

# Summary

GCC and Clang had the best operator-based implementation, using only two `idiv` instructions, whereas MSVC performed a redundant third division.

With `std::div`, MSVC performed much better and used only two `idiv` instructions after inlining the calls while Clang and GCC did not inline the calls.

Neither C++ implementation led to an optimal solution on all three platforms.
For critical functions, it is worth checking the generated assembly to verify assembly is well optimised.

[^1]: From section 3.2.2 of the [System V ABI 0.98](https://refspecs.linuxbase.org/elf/x86_64-abi-0.98.pdf): _"The end of the input argument area shall be aligned on a 16 byte boundary. In other words, the value (%rsp − 8) is always a multiple of 16 when control is transferred to the function entry point."_