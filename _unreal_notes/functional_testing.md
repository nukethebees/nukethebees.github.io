---
layout: hub-post
title: "Functional Testing"
---

# CQTest

## Loading levels
`AddWaitUntilLoadedCommand` is async.
You need to wait until it's done in the test.

```c++
TestCommandBuilder.StartWhen([this] { return nullptr != spawner->FindFirstPlayerPawn(); })
```

## Asserts in Until

`ASSERT_THAT` expands into a `return;` so it's not great for `TestCommandBuilder.Until`.

I recommend calling the assert functions directly:

```c++
if (n_ids < 1) {
    Assert.Fail(TEXT("n_ids < 1"));
    return true;
}
```

The assert functions are in: `\Engine\Source\Developer\CQTest\Public\Assert\NoDiscardAsserter.h`
