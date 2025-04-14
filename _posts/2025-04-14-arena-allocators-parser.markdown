---
layout: post
title:  "[C++] Using arena allocators to improve parser performance"
date:   2025-04-14 12:00:00 +0100
categories: cpp
---

I recently achieved a 12% performance increase in my compiler's parser from using an arena allocator for a single type.
Profiling my benchmark showed that 25% of the runtime was spent calling `new`.
Many of the allocations were very small.

My compiler models expression trees in a flattened form using `std::vector` with pointers to sub-expressions replaced with indexes[^1].
Expressions with dynamic extent such as function calls are modelled with vectors of indexes.
These are small in size but their high numbers resulted in an appreciable performance penalty from calling `new`.

These index vectors now get their memory from an arena allocator associated with the parent module.
Arena memory resources are simple to implement and offer good performance for objects which won't be deallocated until the end of the program.

The original benchmark:

{% highlight txt %}
300 iterations
Duration
Mean: 0.06068419533333333 seconds

Speed
Mean:   743330.5597410172 lines/second
Stddev: 34344.25696097658 lines/second
Median: 754604.3441733645 lines/second
Min:    536969.7721816247 lines/second
Max:    786140.1740339646 lines/second
{% endhighlight %}

With an arena providing memory for the index vectors.

{% highlight txt %}
300 iterations
Duration
Mean: 0.054041255000000024 seconds

Speed
Mean:   835976.9678164988 lines/second
Stddev: 49118.10943593509 lines/second
Median: 852703.9241434588 lines/second
Min:    597588.9278723443 lines/second
Max:    900126.0176424698 lines/second
{% endhighlight %}

The allocator is split into two parts: the arena resource itself and the allocator which controls it.
The code snippets here only show the relevant part of the code under discussion.
[The full source code can be found here.](https://github.com/nukethebees/containers/commit/bed6d97bb7bd998ad66427cc89da1419ca8a608a)

# Arena memory resource and allocator overview

The resource contains `N` pools of memory.
Each pool holds a pointer ot the next pool as well as the total and remaining capacity.
The pools are thus modelled as a singly-linked list.

{% highlight cpp %}
class ArenaMemoryResourcePool {
    ArenaMemoryResourcePool* next_pool_{nullptr};
    std::size_t total_capacity_{0};
    std::size_t remaining_capacity_{0};
};
{% endhighlight %}

The pool is embedded within the byte buffer it controls via placement new.
The buffer's start position can be simply found by adding the size of the class to the `this` pointer.

{% highlight cpp %}
static constexpr std::size_t this_size{
    sizeof(std::remove_cvref_t<decltype(*this)>)};

auto * new_start{static_cast<void *>(
    static_cast<std::byte *>(static_cast<void *>(this))
    + this_size
    + cur_size
)};
{% endhighlight %}

The main functions of the pool are to allocate memory and create a new pool if there is insufficient space.

{% highlight cpp %}
static auto create_pool(std::size_t initial_size) -> ArenaMemoryResourcePool*;

auto next_pool() const -> ArenaMemoryResourcePool const*;
auto total_capacity() const -> std::size_t;
auto remaining_capacity() const -> std::size_t;
auto size() const -> std::size_t;
auto allocate(std::size_t n_bytes, std::size_t alignment) -> void*;
void deallocate(void* alloc, std::size_t n_bytes, std::size_t alignment);
{% endhighlight %}

The parent resource holds pointers to the first and active pools.
Tracking the active pool avoids wasting time traversing the list every time.
When the resource is destroyed, we simply traverse the list and free each buffer.

{% highlight cpp %}
class ArenaMemoryResource {
    ArenaMemoryResourcePool* pool_{nullptr};
    ArenaMemoryResourcePool* last_pool_{nullptr};
    std::size_t initial_capacity_{1024};
};
{% endhighlight %}

The allocator itself is essentially a rough version of `std::pmr::polymorphic_allocator`[^2].
The core of it is:

{% highlight cpp %}
template <typename T, typename MemoryResource>
class MemoryResourceAllocator {
public:
    using pointer = T *;
    using const_pointer = T const *;
    using value_type = T;
    using size_type = std::size_t;
    using difference_type = std::ptrdiff_t;
    MemoryResource * resource_{nullptr};

    template< class U >
    struct rebind {
        using other = MemoryResourceAllocator<U, MemoryResource>;
    };
public:
    [[nodiscard]] auto allocate(size_type n_elems) -> pointer;
    [[nodiscard]] auto reallocate(pointer p, size_type n_elems) -> pointer;
    auto deallocate(pointer, size_type) -> void;
};
{% endhighlight %}

I'll now describe the implementation.

# Implementation

[^1]: <https://www.cs.cornell.edu/~asampson/blog/flattening.html>
[^2]: <https://en.cppreference.com/w/cpp/memory/polymorphic_allocator>