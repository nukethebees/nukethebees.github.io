---
layout: hub
title: "Blender"
---

A hub for Blender notes.

<ul class="post-list">
  {% for note in site.blender_notes %}
    <li class="post-item">
      <a class="post-item-title" href="{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

{% assign blender_articles = site.posts | where_exp: "post", "post.categories contains 'blender'" %}

{% include post_list.html
    title="Articles"
    posts=blender_articles
%}
