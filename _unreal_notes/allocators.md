---
layout: hub-post
title: "Allocators"
last_updated: 2026-07-11 23:58:00 +0100
---

Use `TInlineAllocator` to use some stack allocation before falling back on the heap.

```c++
TArray<int32, TInlineAllocator<16>> values;
```

<https://www.unrealengine.com/blog/optimizing-tarray-usage-for-performance>
