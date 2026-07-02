---
layout: hub-post
title: "AMD μProf with Unreal Engine"
---

[AMD μProf](https://www.amd.com/en/developer/uprof.html) can be used for general profiling (think flame graphs) and deeper CPU introspection (cache misses, branch misses etc) with AMD CPUs.

To use most features on Windows you can't have Hyper-V enabled which means you can't run [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/compare-versions) at the same time.

μProf also needs to be run in admin mode to use most of the deeper features.

# Using the C++ API

AMD μProf has a small C++ library to control it.
Instead of manually starting a run, you can call start/stop functions to only profile the regions of code that you care about.

On Windows, this doesn't work with an already running process.
You need to launch the engine through μProf for this feature to work.

You can launch your project with a command like:

```
<UE>\Engine\Binaries\Win64\UnrealEditor.exe "foo.uproject" -skipcompile
```

You need to launch the profiling session with the "Enable start paused" option enabled.
