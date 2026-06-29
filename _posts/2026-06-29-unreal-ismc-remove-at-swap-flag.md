---
layout: post
title:  "UE5: SetRemoveSwap() turned 493 ms ISMC removal spikes into 31.8 ms in my benchmark"
date:   2026-06-29 20:30:00 +0100
categories: software cpp unreal
---

> tl;dr Call `SetRemoveSwap()` on `InstancedStaticMeshComponent` to massively speed up instance removal times at the cost of losing instance ordering

Unreal Engine's [`InstancedStaticMeshComponent`](https://dev.epicgames.com/documentation/unreal-engine/instanced-static-mesh-component-in-unreal-engine) (ISMC) allows the creation of many instances of a mesh without additional per-instance GPU draw calls.

When removing instances, the instance ordering is maintained by shifting the remaining elements to fill the gap.
This operation has an `O(N)` complexity i.e. the cost scales linearly with the number of instances.
For short-lived and high-volume entities such as projectiles, the cost can be immense.

`ismc->SetRemoveSwap()` changes the ISMC to use an `O(1)` swap-based removal algorithm where the outgoing instance is swapped with the final element.
This is the same as [`TArray<T>::RemoveAtSwap`](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Core/TArray/RemoveAtSwap).

The cost of this approach is the instance ordering is no longer maintained.

# Comparative Benchmark

To evaluate the effect of `SetRemoveSwap`, I ran my game's benchmark for 20s which had had more than 20,000 ISMC-based projectiles at its peak.
The only difference between the two runs was the use of `SetRemoveSwap()`.
Elements were removed using [`RemoveInstances`](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UInstancedStaticMeshComponent/RemoveInstances) with element indices sorted in reverse order for maximum performance.

My core system specs are:

* AMD 5800X3D
* nVidia RTX 5070
* 64 GB DDR4 RAM

## Results overview

The following table describes the longest frame in each run[^1].
The two screenshots show a general overview of the frame times and number of ISMC instances (peak counts are given in the table).

| `SetRemoveSwap?` | Frame time (ms) | FPS | ISMC instances |
| ----- | --------------- | ---------- | -------- |
| Yes | 31.43 | 31.8 | ~24,000 |
| No | 493.68 | 2.0 | ~27,200 |

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/no_swap.webp"
       alt="Benchmark using sorted removal"/>
  <figcaption>
    Frame times with sorted removal
  </figcaption>
</figure>

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/with_swap.webp"
       alt="Benchmark using swapped removal"/>
  <figcaption>
    Frame times with swap-based removal
  </figcaption>
</figure>

The performance difference is staggering.
Without `SetRemoveSwap`, the game is completely unplayable with two large spikes in the frame times grinding the game to a halt.
In contrast, with swap-based removal, the frame times have a gentle rise to a single peak of 31.4 ms (31.8 FPS) and then steadily fall to 18.6 ms (53.8 FPS) by the end.

## Longest frame

The following two figures show a flame graph of the longest frames in each run.

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/no_swap_slowest_frame.webp"
       alt="Slowest frame sorted"/>
  <figcaption>
    Slowest frame with sorted removal
  </figcaption>
</figure>

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/swap_slowest_frame.webp"
       alt="Slowest frame swapped"/>
  <figcaption>
    Slowest frame with swapped removal
  </figcaption>
</figure>


Without `SetRemoveSwap()`, the instance removal took 412.72 ms, dominating the frame time (83.5% of the total).
The swap-based removal time is so small that it cannot be seen with the naked eye at the same zoom level.
It consumes only 66 microseconds, 0.00021% of the frame.
Compared to the 412.72 ms consumed in the other benchmark, swap-based removal takes 0.000016% of the time.

# Takeaway
The lesson here is clear: enabling `SetRemoveSwap()` should be virtually **mandatory** for developers wishing to make extensive use of ISMCs.

The performance benefits are beyond belief.
I feel Epic should have highlighted this setting much more to developers.

## Where was this the whole time?

I only found this after looking through the ISMC source code multiple times.
In the 916 line header, the function is easily missed.

```c++
/** Sets to use RemoveAtSwap on instance removal. 
  * This is an optimization, but will change the 
  * resultant instance reordering. */
void SetRemoveSwap() { bSupportRemoveAtSwap = true; }
```

I had wrongly assumed that swap-based removal was already used given that `RemoveInstances` has a boolean parameter for signalling that the indices are sorted.

```c++
bool RemoveInstances(
    const TArray<int32>& InstancesToRemove, 
    bool bInstanceArrayAlreadySortedInReverseOrder
);
```

[^1]: The instance count differences are likely due to load-related changes in the timestep.