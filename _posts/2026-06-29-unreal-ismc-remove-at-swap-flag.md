---
layout: post
title:  "UE5: Speeding up ISMC instance removal by 6200× with SetRemoveSwap()"
date:   2026-06-29 23:20:00 +0100
categories: software cpp unreal
---

> tl;dr If you do not need stable instance ordering, call `SetRemoveSwap()` on `InstancedStaticMeshComponent` to massively speed up instance removal.

Unreal Engine's [`InstancedStaticMeshComponent`](https://dev.epicgames.com/documentation/unreal-engine/instanced-static-mesh-component-in-unreal-engine) (ISMC) allows the creation of many instances of a mesh without additional per-instance GPU draw calls.

When removing instances, the instance ordering is maintained by shifting the remaining instances to fill the gap.
This operation has `O(N)` complexity i.e. the cost scales linearly with the number of instances.
For short-lived and high-volume entities such as projectiles, the cost can be immense.

`ismc->SetRemoveSwap()` allows ISMC removals to use a swap-based removal path, where the removed instance is swapped with the final instance instead of shifting the remaining instances down.
This is the same idea as [`TArray<T>::RemoveAtSwap`](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Core/TArray/RemoveAtSwap).

The trade-off is that instance ordering is no longer preserved.
If you keep related instance data in parallel arrays, those arrays must also use `RemoveAtSwap()` to stay in sync with the ISMC.

# Comparative Benchmark

To evaluate the effect of `SetRemoveSwap()`, I ran a 20-second benchmark of my game that peaked at over 20,000 ISMC-based projectiles.
The only difference between the two runs was the use of `SetRemoveSwap()`.
Instances were removed using [`RemoveInstances`](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UInstancedStaticMeshComponent/RemoveInstances) with instance indices sorted in reverse order for maximum performance.

My core system specs are:

* AMD 5800X3D
* NVIDIA RTX 5070
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
       alt="Benchmark without swap removal"/>
  <figcaption>
    Frame times without swap removal
  </figcaption>
</figure>

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/with_swap.webp"
       alt="Benchmark with swap removal"/>
  <figcaption>
    Frame times with swap removal
  </figcaption>
</figure>

The performance difference is night and day.
Without `SetRemoveSwap()`, the game becomes effectively unplayable with two large spikes in the frame times grinding the game to a halt.
In contrast, with swap-based removal, the frame times have a gentle rise to a single peak of 31.4 ms (31.8 FPS) and then steadily fall to 18.6 ms (53.8 FPS) by the end.

## Longest frame

The following two figures show flame graphs for the longest frame in each run.

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/no_swap_slowest_frame.webp"
       alt="Slowest frame without swap removal"/>
  <figcaption>
    Slowest frame without swap removal
  </figcaption>
</figure>

<figure class="post-figure">
  <img src="/images/2026-06-29-unreal-ismc-remove-at-swap-flag/swap_slowest_frame.webp"
       alt="Slowest frame with swap removal"/>
  <figcaption>
    Slowest frame with swap removal
  </figcaption>
</figure>


Without `SetRemoveSwap()`, the instance removal took 412.72 ms, dominating the frame time (83.5% of the total).
The swap-based removal time is so small that it cannot be seen with the naked eye at the same zoom level.
It consumes only 66 microseconds, 0.21% of the frame.
Compared to 412.72 ms without `SetRemoveSwap()`, 66 μs for the instance removal is roughly 6,200× faster.

# Takeaway

If your gameplay does not depend on stable instance ordering, `SetRemoveSwap()` should be strongly considered for high-churn ISMCs.

The performance benefits can be enormous for ISMC workloads that frequently remove instances.
I would encourage Epic to highlight this setting in the official ISMC tutorials.

[^1]: The instance count differences are likely due to load-related timestep changes between the two runs.