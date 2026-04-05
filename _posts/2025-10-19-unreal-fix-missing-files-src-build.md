---
layout: post
title:  "UE5: Fix file loading errors when building from source"
date:   2025-10-19 13:51:00 +0100
categories: software c++ unreal
---

When building the Unreal Engine from the [Github source](https://dev.epicgames.com/documentation/en-us/unreal-engine/downloading-source-code-in-unreal-engine) in Visual Studio 2022, the compilation failed due to missing file errors.

An example error:

<div class="wrap-text-highlight">
{% highlight text %}
Cannot open include file: '../Plugins/Developer/Concert/ConcertApp/MultiUserClient/Source/MultiUserClient/Private/Widgets/ActiveSession/Replication/Client/Multi/Columns/AssignedClients/MultiStreamColumns_AssignedClients.cpp': No such file or directory
{% endhighlight %}
</div>

The issue is caused by [Visual Studio 2022 being limited to paths <=260 characters](https://learn.microsoft.com/en-us/answers/questions/1666150/ms-visual-studio-2022-not-able-to-open-source-file) by its use of the [Windows C API's `MAX_PATH` macro](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry).
While Windows can now support longer paths, Visual Studio is still hard-coded to follow this limit.

The solution is to put the Unreal Engine source code near the root of your hard drive e.g. `C:\dev\Unreal Engine\`.
This will ensure no engine paths exceed the `MAX_PATH` limit.