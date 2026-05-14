---
layout: post
title:  "Reverse Dependency Ordering for C++ Includes"
date:   2026-05-14 13:20:00 +0100
categories: software cpp
---

A reliable way to order C++ includes is by using reverse dependency order ([as used by LLVM](https://llvm.org/docs/CodingStandards.html#include-style)) along with a stricter variation of ["Include What You Use" (IWYU)](https://github.com/include-what-you-use/include-what-you-use).

This style makes it easy to detect missing dependencies and avoid fragile builds.

## Reverse dependency ordering

Dependencies should be listed after the headers that depend on them, i.e. 

* The translation unit's (TU) header
* Subsystem headers
* Internal project headers
* External headers
* Standard library headers

For example:

```c++
// foo.cpp

// TU header
#include <proj/foo_module/foo.hpp>

// Subsystem headers
#include <proj/foo_module/bar.hpp>
#include <proj/foo_module/baz.hpp>

// Internal headers
#include <proj/my_other_module/foo.hpp>
#include <proj/my_other_module/bar.hpp>

// External headers
#include <boost/foo.hpp>

// Standard library headers
#include <string>
```

This style helps expose missing dependencies early as builds will typically fail if headers do not include everything they require[^1].

Relying on transitive includes from other headers can cause build instability, e.g.:

```c++
// A.hpp
auto identity(std::uint16_t a) -> std::uint16_t;

// B.hpp
#include <cstdint>

// A.cpp
#include "B.hpp"
#include "A.hpp"

auto identity(std::uint16_t a) -> std::uint16_t {
    return a;    
}
```

This code compiles because `B.hpp` provides `<cstdint>` for `A.hpp`.
If `B.hpp` removes `<cstdint>`, `A.cpp` will fail to compile even though neither `A.hpp` nor `A.cpp` have changed.

As projects grow, issues caused by transitive dependencies become more likely and harder to solve.

## Strict Include What You Use

"Include What You Use" says that every symbol used in a source file should be provided by a header included in the source file or its corresponding header.

I extend this to requiring source files to include their direct dependencies even if they are already declared in the header file.
This can introduce some duplicate includes but reduces hidden coupling between source files and their headers.

This example shows the risk:

```c++
// A.hpp
#include <cstddef>
#include <string>

auto sum_foo() -> std::size_t;
auto bar() -> std::string;

// A.cpp
#include "A.hpp"

auto sum_foo() -> std::size_t {
    std::string foo{"foo"};

    std::size_t result{0};
    for (char c : foo) {
        result += c;        
    }

    return result;    
}
auto bar() -> std::string {
    return "bar";
}
```

`A.cpp` relies on `A.hpp` for the definition of `std::string` and would break if `bar` and `<string>` were removed.

Some people complain that IWYU increases build times due to a misconception that forward declarations are disallowed in headers.
IWYU does not prevent the use of forward declarations, it only requires that the include exists in the header OR source file.

This code uses a valid IWYU style as `Foo`'s full definition is only needed in `A.cpp`.

```c++
// A.hpp
class Foo;

void use_foo(Foo const& foo); 

// A.cpp
#include "A.hpp"

#include "foo.hpp"

void use_foo(Foo const& foo) {
    foo.run();
}
```

## Summary

To reliably identify missing includes:

* Include dependencies after the headers that require them
* Include all used headers in each source file, even if already included in the TU's header file

[^1]: Builds may still succeed if headers are included via other transitive mechanisms like precompiled headers