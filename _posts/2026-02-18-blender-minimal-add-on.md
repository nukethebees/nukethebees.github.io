---
layout: post
title:  "Blender: Creating a minimal Python add-on"
date:   2026-02-15 11:00:00 +0100
categories: software blender
---

This post shows a minimal working example of a Blender Python add-on in Blender 5.0.
[The full source code is found here](https://github.com/nukethebees/github_io_examples/tree/main/blender/minimal_add_on).

Create a directory for your add-on and add the following empty files:
* `__init__.py`
* `operators.py`
* `panels.py`

`__init__.py` contains the loading and unloading code for your module.
Blender loads it when initialising your module.
This is the only mandatory file.

`operators.py` will contain your functions and `panels.py` will hold buttons and other UI elements for calling the functions.
For this example, they are empty.

A minimal `__init__.py`:

```python
import bpy

bl_info = {
    "name": "ExampleAddOn",
    "blender": (5, 0, 0),
    "category": "Object",
}

from . import operators as ops
from . import panels

def register():
    print("Registering ExampleAddOn!")

def unregister():
    print("Unregistering ExampleAddOn!")

if __name__ == "__main__":
    register()
```

Blender loads and unloads your add-on by calling `register` and `unregister` respectively and `bl_info` contains add-on metadata.
The `__name__ == "__main__"` branch lets you run the module directly within Blender using "Run Script".

## Hot reloading

We can enable hot reloading within Blender by adding some extra code to `__init__.py`.
Insert the following lines before `bl_info`:

```python
import importlib
from types import ModuleType
```

The `ModuleType` is used for type annotations and is optional.
After our module imports, add:

```python
modules: tuple[ModuleType] = (
    ops,
    panels
)

if "bpy" in locals():
    for m in modules:
        importlib.reload(m)
```

This groups our modules in a tuple and reimports them in a loop.
To reload your add-ons, press `F3` and run `Reload Scripts`.

## Loading the add-on

In Windows, Blender add-ons reside in `C:\Users\<USER>\AppData\Roaming\Blender Foundation\Blender\<VERSION>\scripts\addons`
For ease of development, I recommend [creating a symbolic link](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/mklink) to your add-on.
By default, your add-on will be in an inactive state.
Navigate to `Preferences/Add-ons` and tick the checkbox next to your module's name to load it.

<figure class="post-figure">
  <img src="/images/2026-02-18-blender-minimal-add-on/preferences.png"
       alt="Blender preferences menu"

       />
  <figcaption>
    The preferences menu
  </figcaption>
</figure>


You can verify that it's working by loading the console with `Window/Toggle System Console`.
This concludes the creation of a minimal Blender add-on with hot-reloading.
