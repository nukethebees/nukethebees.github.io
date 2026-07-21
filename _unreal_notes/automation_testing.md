---
layout: hub-post
title: "Automation Testing"
last_updated: 2026-07-18 13:00:00 +0100
---

## checkCode

The `checkCode` macro is for void check-related code.
It's useful for when you've a heavy duty check that calls `check` or `UE_LOG(..., FATAL)` internally and you want it to be removed in shipping builds.

`checkCode` is controlled by the `DO_CHECK` define in `Build.h`.
Another alternative is to wrap the affected code in `DO_CHECK` checks.

The following example provides an empty implementation when `DO_CHECK` is false which should be optimised out.
This avoids having to put every call in `#if DO_CHECK` blocks.
The downside is that readers may not be aware of the contextual nature of the calls.

```cpp
// MyClass.h
#if DO_CHECK
    void validate_array_sizes() const;
    void check_fighter_tasks() const;
#else
    void validate_array_sizes() const {}
    void check_fighter_tasks() const {}
#endif

// MyClass.cpp
#if DO_CHECK
    void validate_array_sizes() const {
        // check code...
    }
    void check_fighter_tasks() const {
        // check code...
    }
#endif
```

Source: [Asserts in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/asserts-in-unreal-engine)
