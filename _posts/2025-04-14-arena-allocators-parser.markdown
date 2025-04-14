---
layout: post
title:  "[C++] Using arena allocators to improve parser performance"
date:   2025-04-14 12:00:00 +0100
categories: cpp
---

I recently achieved a 12% performance increase in my compiler's parser from using an arena allocator for a single type[^1].
Profiling my benchmark showed that 25% of the runtime was spent calling `new`.
Many of the allocations were very small.

My compiler models expression trees in a flattened form using `std::vector` with pointers to sub-expressions replaced with indexes[^2].
Expressions with dynamic extent such as function calls are modelled with vectors of indexes.
These are small in size but their high numbers resulted in an appreciable performance penalty from calling `new`.
These index vectors now get their memory from an arena allocator associated with the parent module.

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

# Resource and allocator design

[^1]: <https://github.com/nukethebees/containers/commit/bed6d97bb7bd998ad66427cc89da1419ca8a608a>
[^2]: <https://www.cs.cornell.edu/~asampson/blog/flattening.html>