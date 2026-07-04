---
layout: hub
title: "Dev Log"
---

{% assign log_entries = site.dev_log | sort: "date" | reverse %}

{% for entry in log_entries %}
  <h2>
    <a href="{{ entry.url | relative_url }}">
      {{ entry.date | date: "%-d %B %Y" }}
    </a>
  </h2>

  {{ entry.excerpt }}
{% endfor %}
