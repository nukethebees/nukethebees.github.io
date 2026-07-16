---
layout: hub-post
title: "Meshes"
last_updated: 2026-07-04 10:51:00 +0100
---

# Unreal Engine

You can export collision meshes along with your mesh.
Make sure they have the same name as one of the meshes and they're visible in the viewport.

See: <https://dev.epicgames.com/documentation/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine>

<figure class="post-figure">
  <img src="/images/blender_notes/meshes/export_mesh_ubx.webp"
       alt="Blender scene with UBX prefixed collision mesh"/>
  <figcaption>
    Blender scene with UBX prefixed collision mesh
  </figcaption>
</figure>

# Triangulation

N-gons can be messed up when exported to Unreal.
Ctrl+T to triangulate them.

Unreal didn't seem to reimport the UVs when I tried to reimport the mesh.
I had to explicitly drag the mesh from Windows Explorer into Unreal to force a reimport.

<figure class="post-figure">
  <img src="/images/blender_notes/meshes/octagon_uv.webp"
       alt="An N-gon in a UV island"/>
  <figcaption>
    An N-gon in a UV island
  </figcaption>
</figure>
