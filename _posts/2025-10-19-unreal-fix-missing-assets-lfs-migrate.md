---
layout: post
title:  "UE5: Fix missing assets after Git LFS migration"
date:   2025-10-19 12:26:00 +0100
categories: software c++ unreal
---

After migrating my Unreal Engine repository to use [Git Large File Storage](https://git-lfs.com/), all of my assets had vanished.
The solution was to run `git lfs checkout`.

The command ensures that the LFS assets are present on disk.
Without this, the repo only contains pointers to the assets in your LFS remote server.

Sources:

* [Why are all my Unreal Engine uasset files missing after using git lfs migrate import --include="*.uasset"](https://stackoverflow.com/questions/67781391/why-are-all-my-unreal-engine-uasset-files-missing-after-using-git-lfs-migrate-im)
* [Broken git repo after git lfs migrate](https://stackoverflow.com/questions/62060941/broken-git-repo-after-git-lfs-migrate)
* [git-lfs-checkout(1)](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-checkout.adoc)
