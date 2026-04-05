---
layout: post
title:  "Printing class data members using C++26 reflection"
date:   2026-01-31 17:07:00 +0100
categories: software c++
---

C++26's reflection feature allows programs to analyse themselves at compile time ([the proposal paper can be read here](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/p2996r0.html)).
This post illustrates a function to print a struct's data members.
You can [run it here on Compiler Explorer](https://godbolt.org/z/f165eoMoh) using [Bloomberg's reflection-enabled Clang fork](https://github.com/bloomberg/clang-p2996/tree/p2996) (or [view it here on GitHub](https://github.com/nukethebees/github_io_examples/blob/main/cpp26_reflection/print_data_members.cpp)).

## Prerequisites
* Compiler: `x86-64 clang (reflection - C++26)` on [Compiler Explorer](https://godbolt.org/)
* Flags: `-freflection-latest`
* Includes: `<meta>`, `<print>` and `<type_traits>`

## Implementation

The struct whose members we'll print:

```c++
struct Foo {
    int a;
    float b;
    char c;
};
```

To shorten the code, I alias the reflection `std::meta` namespace to `m` using `namespace m = std::meta;`.

This is the full function, followed by a line by line explanation:

```c++
template <typename T>
    requires std::is_class_v<T>
void print_data_members() {
    constexpr auto ctx{m::access_context::unchecked()};
    constexpr auto members{std::define_static_array(m::members_of(^^T, ctx))};

    std::print("Type: {}\n", m::identifier_of(^^T));
    template for (constexpr m::info member : members) {
        if constexpr (m::is_nonstatic_data_member(member)) {
            constexpr auto type{m::type_of(member)};
            std::print("{} : {}\n", 
                       m::identifier_of(member), 
                       m::display_string_of(type)
            );
        }
    }
}

int main() {
    print_data_members<Foo>();

    return 0;
}
```

`print_data_members` uses `std::is_class_v` from `<type_traits>` to reject non-class types.

```c++
template <typename T>
    requires std::is_class_v<T>
```

To access all the class members we will use `std::meta::members_of`.
Its parameters are an `std::meta::info` object and an access context specifier.
The `info` object can be created using the reflection "cat-ears" operator `^^` on our struct type.

`access_context` is used to control the level of access when reflecting on a type e.g. can you see private member variables or not?

We need to feed the `members_of` output to `std::define_static_array` as the `std::vector<info>` returned by `members_of` cannot be used in a `constexpr` context.
This is explained in the ["Expansion Statements" paper](https://isocpp.org/files/papers/P1306R5.html#expansion-over-ranges).

```c++
constexpr auto ctx{m::access_context::unchecked()};
constexpr auto members{std::define_static_array(m::members_of(^^T, ctx))};
```

I get and print the struct's name using `std::meta::identifier_of` and `std::print` respectively.

```c++
std::print("Type: {}\n", m::identifier_of(^^T));
```

The new `template for` does a compile-time loop over our `members` array.

```c++
template for (constexpr m::info member : members) {}
```

I filter out non-data members using `if constexpr (m::is_nonstatic_data_member(member))`.
I get the member's type with `std::meta::type_of`.
`std::meta::identifier_of` throws compiler errors for primitive types like `int` so we use `std::meta::display_string_of` instead.

```c++
constexpr auto type{m::type_of(member)};
std::print("{} : {}\n", m::identifier_of(member), m::display_string_of(type));
```

In our main function, we call `print_data_members` like any other function template.

```c++
print_data_members<Foo>();
```

The program's output is:

```text
Type: Foo
a : int
b : float
c : char
```

References:

* [learning reflection?](https://old.reddit.com/r/cpp_questions/comments/1lq27uq/learning_reflection/)
* [Expansion Statements](https://isocpp.org/files/papers/P1306R5.html#expansion-over-ranges)
* [libcxx/include/meta](https://github.com/bloomberg/clang-p2996/blob/p2996/libcxx/include/meta)
* [Modeling Access Control With Reflection](https://open-std.org/jtc1/sc22/wg21/docs/papers/2025/p3547r0.html)