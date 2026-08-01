---
layout: hub-post
title: "Project Structure"
last_updated: 2026-07-25 11:00:00 +0100
---

Split your game over multiple modules.
These can coexist within `Source/`.

You could have modules such as:

| Name | Purpose |
| --- | --- |
| `Game` | Main game code |
| `GameEditor` | Editor code |
| `GameNative` | Engine/editor independent code |
| `GameNativeTests` | Tests for `GameNative` |
| `GameTests` | Tests for `Game`  |

For `GameNativeTests`, I recommend using [low level tests](https://dev.epicgames.com/documentation/unreal-engine/low-level-tests-in-unreal-engine).
These run quickly and are run outside of the editor itself.

For `GameTests`, [CQ tests](https://dev.epicgames.com/documentation/unreal-engine/cqtest-test-framework-for-unreal-engine) (which build on the automation framework) are recommended.
These allow you to create levels for tests and can handle anything within the engine.

Low-level tests can compile against the engine and editor but I have had difficulty making it work well so I don't recommend it.

## Plugins

I recommend creating a game content plugin using something like [Git LFS](https://git-lfs.com/).
This allows you to keep your content out of the main game module which can be left leaner.
It also allows you to open-source your game without exposing paid content publicly.

A plugin for reusable code is also recommended.
