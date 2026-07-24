---
layout: hub-post
title: "Low Level Tests"
last_updated: 2026-07-24 20:23:00 +0100
---

<https://dev.epicgames.com/documentation/unreal-engine/low-level-tests-in-unreal-engine>

## Placing LLTs in the game module

You can place LLTs directly in the game module.
The documentation assumes you will put them directly in the engine or a plugin.

```
<path_to_game>\ue5_sandbox\Source\SandboxLowLevelTests
|   .clang-format
|   SandboxLowLevelTests.Build.cs
|   SandboxLowLevelTests.Target.cs
|
\---Private
        test_string.cpp
```
