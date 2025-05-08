---
layout: post
title:  "Sending commands from Visual Studio 2022 to gdb in WSL 2"
date:   2025-05-08 20:00:00 +0100
categories: cpp
---

I recently set up a Linux build of my compiler using WSL2 and Visual Studio.
Sending commands to gdb was unintuitive but I found out how to [here](https://github.com/microsoft/MIEngine/wiki/Executing-custom-gdb-lldb-commands)[^1].

When debugging an executable in VS2022, go to: `View -> Other Windows -> Command Window`.
Within the command window, prefix gdb commands with `Debug.MIDebugExec`, e.g.:

{% highlight text %}
Debug.MIDebugExec print x
{% endhighlight %}

[^1]: The link was nestled in this article: <https://learn.microsoft.com/en-us/cpp/build/configure-cmake-debugging-sessions?view=msvc-170>

