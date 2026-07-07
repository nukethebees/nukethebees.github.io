---
layout: post
title:  "Fixing extremely slow Git commands on Windows on a corporate network"
date:   2026-07-07 10:20:00 +0100
categories: software
---

> tl;dr Set `%HOME%` on Windows to a non-networked directory

Git had terrible performance on my Windows laptop at work.

`git branch` could take 15 seconds to run, while `git status` could take 30 to 60 seconds.

I initially suspected the workplace virus scanner, but the actual cause was a network drive.

When reading `.gitconfig`, Git looks in `%HOME%` first[^1].
If `%HOME%` isn't defined, Git defines it internally as `%HOMEDRIVE%%HOMEPATH%`[^2].

On my machine, `%HOME%` was unset and `%HOMEDRIVE%` was mapped to a network drive.

Setting `%HOME%` to my local user directory fixed the problem immediately.

[^1]: <https://git-scm.com/docs/git#Documentation/git.txt-GITCONFIGSYSTEM>
[^2]: <https://git-scm.com/docs/git#Documentation/git.txt-HOME>
