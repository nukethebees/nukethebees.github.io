---
layout: post
title:  "Disabling Firefox's Accessibility Services to improve performance"
date:   2025-09-10 10:47:00 +0100
categories: software
---

{% assign block_padding = "16px" %}
{% capture vertical_padding %} padding-top: {{ block_padding }}; padding-bottom: {{ block_padding }}; {% endcapture %}

My work laptops have had extremely poor performance with Mozilla Firefox's default configuration.
Tabs would frequently hang for multiple seconds so the browser was very frustrating to use.
The solution was to disable Firefox's Accessibility Services.

Go to `about:config`,  move past the warning message, and then follow these steps.

<figure style="{{ vertical_padding }}; text-align: center;">
  <img src="/images/firefox_about_config.PNG" 
       alt="Firefox about:config warning screen" 
       style="max-width: 100%; height: auto; display: inline-block; border: 1px solid #ccc;" 
       />
  <figcaption style="margin-top: 8px; font-style: italic; color: #555;">
    The warning page that appears when opening about:config
  </figcaption>
</figure>

* Type `accessibility.force_disabled` into the search bar
* Double click on the number if it is `0` (false)
* Set the number to `1` (true)
* Click the blue tick to save the setting

<figure style="{{ vertical_padding }}; text-align: center;">
  <img src="/images/firefox_accessibility_force_disabled.png" 
       alt="Firefox accessibility.force_disabled configuration setting screenshot" 
       style="max-width: 100%; height: auto; display: inline-block; border: 1px solid #ccc;" 
       />
  <figcaption style="margin-top: 8px; font-style: italic; color: #555;">
    The configuration variable to change.
  </figcaption>
</figure>

That's it, you're good to go.

<div style="border: 1px solid #dcdcdc; background-color: #f7f7f7; padding: 12px; border-radius: 6px; font-style: italic; color: #555;">
  Thanks to <a href="https://old.reddit.com/r/firefox/comments/p8g5zd/why_does_disabling_accessibility_services_improve/" target="_blank">/u/Shiedheda on Reddit</a> for finding this solution.
</div>
