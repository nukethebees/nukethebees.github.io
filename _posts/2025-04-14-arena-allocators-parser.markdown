---
layout: post
title:  "[C++] Using arena allocators to improve parser performance"
date:   2025-04-14 12:00:00 +0100
categories: cpp
---

I recently achieved a 12% performance increase in my compiler's parser using arena allocators.
Profiling showed that 25% of the parser's runtime was spent calling `new`, often for very small allocations.

The compiler uses `std::vector` to model expressions as a flattened tree.
Nodes point to children using vector indexes in place of pointers[^1].
Expressions with dynamic extent (e.g. function calls) contain vectors of indexes.
Constructing each one may result in 1-2 calls to `new` to store a handful of bytes.
Given that expressions generally live for the duration of the program, these allocations could be handled by a much simple allocator than `new`.

The solution was to build an arena allocator to allocate a large amount of memory up front (e.g. 10,000 bytes) and then distribute it locally at much higher speeds. 

The parsing benchmark consists of processing a 45,000 line file 300 times.
Three consecutive runs resuled in a top average speed of 743,000 lines per second (lines/s).

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

With the arena allocator, best average increased from 743k lines/s to 835k lines/s.

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

The allocation system is divided into a memory resource that owns the memory and an allocator which holds a pointer to the resource and calls it when needed.
I'll describe the core design now [(the full source can be found here.)](https://github.com/nukethebees/containers/commit/bed6d97bb7bd998ad66427cc89da1419ca8a608a)

# Arena memory resource and allocator overview

The memory resource consists of pools connected in a singly-linked list.
A pool consists of a byte array, a child pointer, and variables for the total and remaining capacities.
The byte array's address can be determined from context and thus doesn't need to be stored in a separate pointer.

{% highlight cpp %}
class ArenaMemoryResourcePool {
    ArenaMemoryResourcePool* next_pool_{nullptr};
    std::size_t total_capacity_{0};
    std::size_t remaining_capacity_{0};
};
{% endhighlight %}

To remove the need for the array pointer, we allocate `sizeof(Pool)` extra bytes for the byte array and then embed the pool within its own array.
The array's starting address is thus `this + sizeof(Pool)` and the first free byte for allocation is found using the pool's size as an offset.

{% highlight cpp %}
auto const cur_size{size()};

static constexpr std::size_t this_size{
    sizeof(std::remove_cvref_t<decltype(*this)>)};

auto * new_start{static_cast<void *>(
    static_cast<std::byte *>(static_cast<void *>(this))
    + this_size
    + cur_size
)};
{% endhighlight %}

The `ArenaMemoryResource` class controls the pools.
It holds start/end pointers and the capacity for the first pool.
The tail pointer saves traversing the list for each allocation at the cost of a single extra pointer.

{% highlight cpp %}
class ArenaMemoryResource {
    ArenaMemoryResourcePool* pool_{nullptr};
    ArenaMemoryResourcePool* last_pool_{nullptr};
    std::size_t initial_capacity_{1024};
};
{% endhighlight %}

When the resource is destroyed, we recursively free each byte array.

{% highlight cpp %}
ArenaMemoryResource::~ArenaMemoryResource() {
    if (pool_) {
        pool_->~ArenaMemoryResourcePool();
        delete[] reinterpret_cast<std::byte *>(pool_);
    }
}
ArenaMemoryResourcePool::~ArenaMemoryResourcePool() {
    if (next_pool_) {
        next_pool_->~ArenaMemoryResourcePool();
        delete[] reinterpret_cast<std::byte *>(next_pool_);
    }
}
{% endhighlight %}

The allocator itself is similar to `std::pmr::polymorphic_allocator`[^2] and just holds a `ArenaMemoryResource*` and calls its allocation methods.
The allocator's implementation will not be covered as the main logic lies within the resource.

# Implementation

When the allocator requests bytes from the resource, the resource checks for a valid pool with sufficient capacity.
If none is available, a new pool of sufficient size is created.
The resource then calls the pool's allocate function.

{% highlight cpp %}
auto ArenaMemoryResource::allocate(std::size_t n_bytes, std::size_t alignment) -> void * {
    if (!last_pool_) {
        auto const cap{initial_capacity_};
        auto const new_size{ml::max(cap * 2, (n_bytes / cap) * 2 * cap)};
        pool_ = ArenaMemoryResourcePool::create_pool(new_size);
        last_pool_ = pool_;
        return last_pool_->allocate(n_bytes, alignment);
    }

    if (last_pool_->remaining_capacity() <= n_bytes) {
        auto const cap{last_pool_->total_capacity()};
        auto const new_size{ml::max(cap * 2, (n_bytes / cap) * 2 * cap)};
        last_pool_->next_pool_ = ArenaMemoryResourcePool::create_pool(new_size);
        last_pool_ = last_pool_->next_pool_;
        return last_pool_->allocate(n_bytes, alignment);
    }

    return last_pool_->allocate(n_bytes, alignment);
}
{% endhighlight %}

The pool is created by allocating `sizeof(Pool) + new_capacity` bytes and then constructing the object at the start of the array.

{% highlight cpp %}
auto ArenaMemoryResourcePool::create_pool(std::size_t initial_size) -> ArenaMemoryResourcePool * {
    std::size_t const bytes_needed{initial_size + sizeof(ArenaMemoryResourcePool)};
    auto * buffer{new std::byte[bytes_needed]};
    return new (buffer) ArenaMemoryResourcePool(initial_size);
}
{% endhighlight %}

The aligned allocation address is calculated using `std::align` and the capacity is updated before returning the pointer.

{% highlight cpp %}
auto ArenaMemoryResourcePool::allocate(std::size_t n_bytes, std::size_t alignment) -> void * {
    auto const cur_size{size()};

    static constexpr std::size_t this_size{
        sizeof(std::remove_cvref_t<decltype(*this)>)};

    auto * new_start{static_cast<void *>(
        static_cast<std::byte *>(static_cast<void *>(this))
        + this_size
        + cur_size)};

    if (!std::align(alignment, n_bytes, new_start, remaining_capacity_)) {
        throw std::bad_alloc{};
    }

    remaining_capacity_ -= n_bytes;
    return new_start;
}
{% endhighlight %}

The allocator can then be used with STL components by setting it as the container's type parameter.

{% highlight cpp %}
ml::ArenaMemoryResource resource;
ml::ArenaAllocator<int> alloc{&resource};
std::vector<int, ml::ArenaAllocator<int>> vec{alloc};

// Reserve space and emplace elements
vec.reserve(10);
vec.emplace_back(10);
vec.emplace_back(20);
{% endhighlight %}

Finally, the arena's deallocate method is a no-op as the memory is reclaimed when the entire structure is destroyed.
Arenas are thus unsuitable for use with objects with short or indeterminate lifetimes but offer very high speeds when its objects are all destroyed together.

[^1]: <https://www.cs.cornell.edu/~asampson/blog/flattening.html>
[^2]: <https://en.cppreference.com/w/cpp/memory/polymorphic_allocator>