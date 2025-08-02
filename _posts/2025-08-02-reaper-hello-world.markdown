---
layout: post
title:  "[C++] \"Hello World\" in the Reaper DAW"
date:   2025-08-02 16:00:00 +0100
categories: programming cpp reaper
---

Full code can be found [here](https://github.com/nukethebees/github_io_examples/tree/main/reaper_sdk).

This article covers creating a Reaper plugins in C++ that prints "Hello world!" to the console.

Plugins are created by building a dynamic link library (DLL) with the [reaper software development kit (SDK)](https://github.com/justinfrankel/reaper-sdk/tree/main) and placing it in the `UserPlugins` directory.

## Project Setup

1. Copy `reaper_plugin.h` and `reaper_plugin_functions.h` into the project.
2. For a leaner DLL you can enable only the SDK functions you need by defining `REAPERAPI_MINIMAL` in the preprocessor then using `REAPERAPI_WANT_<function>` to enable specific functions.
3. Define `REAPERAPI_WANT_ShowConsoleMsg` to print to the console

### Building with CMake

I'm using CMake as my build tool so my DLL's target `CMakeLists.txt` looks like this:

```cmake
add_library(reaper_sdk SHARED
    "main.cpp"
    "main.hpp"
    "reaper_plugin.h"
    "reaper_plugin_functions.h"
)

target_compile_definitions(reaper_sdk PRIVATE
                           REAPERAPI_MINIMAL
                           REAPERAPI_WANT_ShowConsoleMsg
)
```

## Defining the entry point

### Header

The plugins's entry point function is defined with the SDK's `REAPER_PLUGIN_ENTRYPOINT` macro.
Enable C linkage with `extern "C"` and use `REAPER_PLUGIN_DLL_EXPORT` from the SDK to export the function's symbol from the DLL.

Our header file looks like this:

```cpp
#pragma once

#include "reaper_plugin.h"

extern "C" {
    REAPER_PLUGIN_DLL_EXPORT
    int REAPER_PLUGIN_ENTRYPOINT(HINSTANCE hInstance, reaper_plugin_info_t* rec);
}
```

### Implementation

Define `REAPERAPI_IMPLEMENT` in a single translation unit to instantiate the SDK's functions.

```cpp
#define REAPERAPI_IMPLEMENT
#include "reaper_plugin_functions.h"

#include "main.hpp"
```

Define a global variable to store the plugin information struct that's passed to our entry point function.

```cpp
reaper_plugin_info_t* g_rec = nullptr;
```

Now, implement the entry point function.

```cpp
extern "C" {
    REAPER_PLUGIN_DLL_EXPORT
    int REAPER_PLUGIN_ENTRYPOINT(HINSTANCE hInstance, reaper_plugin_info_t* rec) {
        // Impl goes here
    }
}
```

Check that `rec` is valid and load the API functions using `REAPERAPI_LoadAPI`.

`REAPERAPI_LoadAPI` returns the number of functions which failed to load.
If there is an error, return `0` to indicate failure.

```cpp
if (!rec || (REAPERAPI_LoadAPI(rec->GetFunc) > 0)) {
    return 0;
}
```

Save the pointer to our global variable, call `ShowConsoleMsg` to print "Hello World!" to the Reaper console, and then return 1 to indicate success.

```cpp
g_rec = rec;
ShowConsoleMsg("Hello world!");
return 1;
```

This is our function in full.

```cpp
extern "C" {
    REAPER_PLUGIN_DLL_EXPORT
    int REAPER_PLUGIN_ENTRYPOINT(HINSTANCE hInstance, reaper_plugin_info_t* rec) {
        if (!rec || (REAPERAPI_LoadAPI(rec->GetFunc) > 0)) {
            return 0;
        }

        // Save the info ptr
        g_rec = rec;

        ShowConsoleMsg("Hello world!");

        return 1;
    }
}
```

## Using the DLL

Place the compiled DLL in the `UserPlugins` directory.
You can find it in Reaper by clicking `Options->Show REAPER resource path in explorer/finder...`.
Reload Reaper after copying the DLL and you should see the following message.

<figure style="text-align: center;">
  <img src="/images/hw.png" alt="Reaper Hello World Message" style="max-width: 100%; height: auto; display: inline-block;" />
  <figcaption style="margin-top: 8px; font-style: italic; color: #555;">
    The Reaper "Hello World!" message.
  </figcaption>
</figure>
