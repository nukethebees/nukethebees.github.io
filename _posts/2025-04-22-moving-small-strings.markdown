---
layout: post
title:  "[C++] Moving small strings can invalidate data pointers"
date:   2025-04-22 19:00:00 +0100
categories: cpp asm
---

Heap allocated structures can generally be moved without invalidating pointers to the underlying data however this doesn't always hold true with `std::string`.

If strings are small enough the character data can be held in the storage reserved for the class members instead of allocating on the heap.
This is called _small string optimisation_[^2].
If our string's data is stored internally then moving the object will naturally change the data's address and invalidate any views to the data.

I encountered this issue when I used `std::vector<std::string>`.
When the vector ran out of room and reallocated, many of my `std::string_view` instances became invalid and crashed the program.

This example shows the behaviour[^1].

{% highlight cpp %}
#include <print>
#include <string>

int main() {
    std::string small_string{"foo"};
    auto* ss_ptr0{small_string.data()};

    auto moved_ss{std::move(small_string)};
    auto* ss_ptr1{moved_ss.data()};

    std::string large_string{"fooooooooooooooooooooooooooooooooooooooooooooooooooooo"};
    auto* ls_ptr0{large_string.data()};

    auto moved_ls{std::move(large_string)};
    auto* ls_ptr1{moved_ls.data()};

    std::print("Small string addresses are equal: {}\n", ss_ptr0 == ss_ptr1);
    std::print("Large string addresses are equal: {}\n", ls_ptr0 == ls_ptr1);

    return 0;
}
{% endhighlight %}

We can see that the addresses are not equal for small strings.

{% highlight text %}
Small string addresses are equal: false
Large string addresses are equal: true
{% endhighlight %}

A simple (though inefficient) solution is to simply reserve enough characters in the string to force heap allocation.

[^1]: <https://godbolt.org/z/hxWf1Mnnz>
[^2]: <https://devblogs.microsoft.com/oldnewthing/20230803-00/?p=108532>