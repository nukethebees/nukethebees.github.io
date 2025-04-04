---
layout: post
title:  "Why won't MSVC generate assembly listings for my library in release mode?"
date:   2025-04-04 18:49:00 +0100
categories: cpp
---

I recently had an issue where MSVC wouldn't generate assembly files for my library when in release mode.
The files would appear when compiling and linking the whole application.

The issue was that enabling whole program optimisation (`/GL`, [^1]) would lead to the entire library being optimised out!
Thankfully Ovod posted the solution on stackoverflow[^2].

[^1]: <https://learn.microsoft.com/en-us/cpp/build/reference/gl-whole-program-optimization?view=msvc-170>
[^2]: <https://stackoverflow.com/questions/59088426/visual-studio-2019-do-not-want-to-produce-asm-files-for-lib-release-what-im-do>