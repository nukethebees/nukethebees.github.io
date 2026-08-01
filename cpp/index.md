---
layout: hub
title: "C++"
---

A hub for C++ notes.

<ul class="post-list">
  {% for note in site.cpp_notes %}
    <li class="post-item">
      <a class="post-item-title" href="{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

{% assign cpp_articles = site.posts | where_exp: "post", "post.categories contains 'cpp'" %}

{% include post_list.html
    title="Articles"
    posts=cpp_articles
%}
