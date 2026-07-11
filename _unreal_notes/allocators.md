---
layout: hub-post
title: "Allocators"
---

Use `TInlineAllocator` to use some stack allocation before falling back on the heap.

```c++
TArray<int32, TInlineAllocator<16>> values;
```

<https://www.unrealengine.com/blog/optimizing-tarray-usage-for-performance>
