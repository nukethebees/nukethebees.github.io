---
layout: post
title:  "Fixing Command & Conquer 3 / Kane's Wrath crash to desktop on Windows 11 Pro N"
date:   2025-06-30 12:50:00 +0100
categories: misc
---

After Windows 11 Pro N was installed on a friend's PC, the game Command & Conquer 3 and its expansion Kane's Wrath would no longer load. The game's splash screen would appear and then it would silently crash.

The fix was to install the Windows Media Feature Pack. It appears that C&C3 relies on some codecs which are omitted on N-editions of Windows.

[The installation instructions can be found here.](https://support.microsoft.com/en-us/windows/media-feature-pack-for-windows-10-11-n-september-2022-78cfeea5-c7d9-4aa8-b38f-ee4df1392009)

* Search for "Optional Features" in Windows 11
* Click "Add a feature"
* Install "Media Feature Pack for Windows 11 N"

The installation took many hours, maybe as many as 10 but it fixed the issue. There are many posts and fixes online for this issue but none worked for me except this one.