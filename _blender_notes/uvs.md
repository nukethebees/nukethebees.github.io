---
layout: hub-post
title: "UVs"
---

## UV Packing Margin

Add margins to space out the islands.
The value ranges from 0 to 1 as a proportion of the image.

With 0 margins, the islands will likely be touching each other.
As textures use a discrete grid, this can cause colours on one texel to bleed across two islands.

<figure class="post-figure">
  <img src="/images/blender_notes/texture_painting/uv_packing_margin.webp"
       alt="UV Packing Margin"/>
  <figcaption>
    UV Packing Margin
  </figcaption>
</figure>
