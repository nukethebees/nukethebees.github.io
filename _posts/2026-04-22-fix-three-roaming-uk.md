---
layout: post
title:  "Fixing disabled iPhone 17 Pro roaming in the UK on Three Ireland"
date:   2026-04-22 21:00:00 +0100
categories: misc
---

My iPhone 17 Pro would not let me enable roaming when I travelled to Northern Ireland recently from ROI.
The hotspot button was greyed out and unresponsive.
I use Three Ireland as my network.

The solution was to navigate to:
* Navigate to `Settings->Mobile Service`
* Select your sim card under "SIMs"
* Go to "Mobile Data Network"
* Change the APN under "Personal Hotspot" from `open.internet` to `internet`.

My hotspot began working immediately.