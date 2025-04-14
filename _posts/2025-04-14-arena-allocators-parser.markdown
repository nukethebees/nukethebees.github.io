---
layout: post
title:  "[C++] Using arena allocators to improve parser performance"
date:   2025-04-14 12:00:00 +0100
categories: cpp
---

I recently achieved a 12% performance increase in my compiler's parser using arena allocators.
25% of the parser's runtime was spent calling `new`, often for small vectors.

My compiler uses `std::vector` to model expressions in a flattened form with pointers to sub-expressions replaced with indexes[^1].
Expressions with dynamic extent (e.g. function calls) contain vectors of indexes.
Building each call expression may result in 1-2 costly calls to `new` only to store a handful of bytes.
The index vectors generally live for the duration of the program and thus could be served by a more simple allocator.

My solution was to build an arena allocator to allocate a large amount of memory up front (e.g. 10,000 bytes) and then distribute it locally at much higher speeds.

The original benchmark had an average speed of 743,000 lines per second.
The benchmark was run three times in a row on a 45,000 line file.

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

With the arena allocator, the mean speed increased from 743k lines/second to 835k lines/second.

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

I'll now cover the design of the allocator and the underlying memory resource.
For brevity, extraneous code will be omitted but [the full source can be found here.](https://github.com/nukethebees/containers/commit/bed6d97bb7bd998ad66427cc89da1419ca8a608a)

# Arena memory resource and allocator overview

The memory resource consists of "pools" connected in a singly-linked list.
A pool consists of a byte array, a pointer to the next pool, and the total and remaining capacities.
The byte array's address can be determined from context.

{% highlight cpp %}
class ArenaMemoryResourcePool {
    ArenaMemoryResourcePool* next_pool_{nullptr};
    std::size_t total_capacity_{0};
    std::size_t remaining_capacity_{0};
};
{% endhighlight %}

The pool is embedded within its byte array via placement new and thus we can determine the array's address by adding the pool's size to the `this` pointer.
Adding the buffer's current size gives the address of the first free byte in the array.

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

The `ArenaMemoryResource` class acts as the parent of the pools.
It tracks the first and last pools as well as the capacity to give the first pool.
Pointing to the last pool saves wasting time traversing the list for each allocation at the cost of a single extra pointer.

{% highlight cpp %}
class ArenaMemoryResource {
    ArenaMemoryResourcePool* pool_{nullptr};
    ArenaMemoryResourcePool* last_pool_{nullptr};
    std::size_t initial_capacity_{1024};
};
{% endhighlight %}

When the resource is destroyed, we simply traverse the list and free each buffer in reverse order.

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

The allocator itself is essentially a rough version of `std::pmr::polymorphic_allocator`[^2].
It just holds a `ArenaMemoryResource*` and calls its allocation methods.
The allocator is not worth covering as the logic lies within the resource and pool classes.

# Implementation

The resource checks if there is a valid pool and if it has sufficient capacity.
If not, a new pool of sufficient size is created.
The new size is determined by the capacity of the last pool and the number of bytes being allocated.
The pool then allocates the bytes needed.

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

The pool itself is created simply by calling `new` to get enough bytes for the buffer and the `Pool` object and then emplacing the new `Pool` instance into the top of the buffer.

{% highlight cpp %}
auto ArenaMemoryResourcePool::create_pool(std::size_t initial_size) -> ArenaMemoryResourcePool * {
    std::size_t const bytes_needed{initial_size + sizeof(ArenaMemoryResourcePool)};
    auto * buffer{new std::byte[bytes_needed]};
    return new (buffer) ArenaMemoryResourcePool(initial_size);
}
{% endhighlight %}

The allocation calculates the first available address and then calls `std::align` to ensure we've an aligned address.
If the `align` call succeeds, we update our remaining capacity and return the pointer.

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

[^1]: <https://www.cs.cornell.edu/~asampson/blog/flattening.html>
[^2]: <https://en.cppreference.com/w/cpp/memory/polymorphic_allocator>