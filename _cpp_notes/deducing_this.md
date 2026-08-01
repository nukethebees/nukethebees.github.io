---
layout: hub-post
title: "Deducing this"
last_updated: 2026-07-26 12:00:00 +0100
---

## Reference parameters can bind to mutable and const refs

When using a template parameter to do `deducing this`, `T` in `T&` can evaluate to `T` and `T const`, covering both lvalue reference cases.

<https://godbolt.org/z/bYsddren8>

```cpp
#include <type_traits>

struct Foo {
    template <typename Self>
    auto get(this Self& self) -> auto& {
        return self.a;
    }

    int a;
};

int main() {
    Foo foo{0};

    auto& mut_foo{foo};
    auto& mut_a{mut_foo.get()};
    static_assert(std::is_same_v<int&, decltype(mut_a)>);

    auto const& cref_foo{foo};
    auto const& cref_a{cref_foo.get()};
    static_assert(std::is_same_v<int const&, decltype(cref_a)>);

    return 0;
}
```
