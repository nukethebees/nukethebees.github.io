---
layout: post
title:  "Blender: Fixing meshes disappearing when zooming out"
date:  2026-04-02 20:00:00 +0100
categories: software blender
---

In Blender, objects may disappear when you are far enough away from them.
This is due to the camera moving outside of the clipping distance.
By default, Blender renders things between 1cm to 1000m.

Access the clipping settings by pressing `N` then opening the "View" panel as shown below.
Adjust the "Clip Start" and "End" values as needed.

<figure class="post-figure">
  <img src="/images/2026-04-02-blender-clipping-fix/clip.webp"
       alt="The clipping panel"/>
  <figcaption>
    The clipping panel
  </figcaption>
</figure>
