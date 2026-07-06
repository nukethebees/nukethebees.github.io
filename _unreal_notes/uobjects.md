---
layout: hub-post
title: "UObjects"
---

## Add a button to the editor details panel

Using `CallInEditor` with `UNFUNCTION` allows you to put a button in the editor details panel.

```c++
UFUNCTION(CallInEditor, Category = "Ship")
void apply_asset_configuration();
```

<figure class="post-figure">
  <img src="/images/unreal_notes/uobjects/details_button.webp"
       alt="A UFunction button in an actor's details panel"/>
  <figcaption>
    A UFunction button in an actor's details panel
  </figcaption>
</figure>
