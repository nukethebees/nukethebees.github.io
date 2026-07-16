---
layout: hub-post
title: "Instanced Static Mesh Components"
last_updated: 2026-07-12 5:25:00 +0100
---

Notes on [Instanced Static Mesh Component](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UInstancedStaticMeshComponent) behaviour, update costs, removal, and batching.

# Efficient updates

## Transforms

Batched updates are more efficient than individual updates.

Prefer functions like `BatchUpdateInstancesTransforms` and `BatchUpdateInstancesData` over `UpdateInstanceTransform`.

For the fastest update speed, I found constructing a `TArray<FInstancedStaticMeshInstanceData>` with `ParallelFor` and then using `BatchUpdateInstancesData` worked best.

`BatchUpdateInstancesTransforms` takes a `TArrayView<FTransform>` and converts it to an `FMatrix` internally.

`BatchUpdateInstancesData` takes a `FInstancedStaticMeshInstanceData*` and copies the `FMatrix` elements directly.

For single-threaded updates, I found `BatchUpdateInstancesData` to be slower overall than `BatchUpdateInstancesTransforms`, because the cost of constructing the array of 128-byte `FInstancedStaticMeshInstanceData` was greater than the time saved in `BatchUpdateInstancesData`. For comparison,  `FTransform` is 96 bytes.

However, with multithreading the story changes. You can build a `TArray<T>` very quickly using `TArray<T>::AddUninitialized(count)` and then constructing the elements using multiple threads.

Since the ISMC update functions are not thread-safe, my testing showed that they became the dominant serial cost. `FMatrix`-based updates were the fastest.

The main cost is the extra 32 bytes needed per element using `FMatrix`-based instance data instead of `FTransform`, but this is  small in the context I work at.

## Per-instance custom data

There isn't a lot of choice here but this overload allows you to write everything in one call.

```c++
SetCustomData(int32 InstanceIndexStart,
              int32 InstanceIndexEnd,
              TConstArrayView<float> CustomDataFloats,
              bool bMarkRenderStateDirty = false);
```

On one of my benchmarks, updating 3 floats on 2800 instances took about 20 μs using the "Development Editor" config.

# Articles

* [UE5: Speeding up ISMC instance removal by 6200× with SetRemoveSwap()]({{ "/unreal-ismc-remove-at-swap-flag/" | relative_url }})
