---
layout: post
title:  "Updating a vcpkg port in a custom registry"
date:   2025-07-20 12:00:00 +0100
categories: programming cpp
---

This post documents how to update a vcpkg registry port. In this example, we will be updating the `ml-cpp-utils` port.

# Update the ref and SHA512

Navigate to `/ports/ml-cpp-utils/portfile.cmake`

Update the `REF` field to the git commit/tag/release of the upstream repo and set the `SHA512` field to 0.

{% highlight cmake %}
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO nukethebees/cpp_utils
    REF b342e3eea9538c7a35019b56f21a5f50439a4f74
    SHA512 0
    HEAD_REF master
)
{% endhighlight %}

We must install our port to get the SHA512 value.
If the package is already installed locally then first run

{% highlight text %}
vcpkg remove ml-cpp-utils
{% endhighlight %}

Install the package using

{% highlight text %}
vcpkg install ml-cpp-utils --overlay-ports=./ports
{% endhighlight %}

You should get an error that includes the SHA512 value.

{% highlight text %}
error: failing download because the expected SHA512 was all zeros, please change the expected SHA512 to: 97b2a6b1770595559185e75405a28af191765fbbc9827ea06ae507086b3a599aecc6f2520cc75a2f53be0bf4db829ebc55fb6ddf814405bee7b6b70d84b9529f
{% endhighlight %}

Replace the 0 with the new value.

{% highlight cmake %}
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO nukethebees/cpp_utils
    REF b342e3eea9538c7a35019b56f21a5f50439a4f74
    SHA512 97b2a6b1770595559185e75405a28af191765fbbc9827ea06ae507086b3a599aecc6f2520cc75a2f53be0bf4db829ebc55fb6ddf814405bee7b6b70d84b9529f
    HEAD_REF master
)
{% endhighlight %}

Commit your changes to the git repo. You must commit these changes for the next step to work correctly.

## Updating the version or port-version

Navigate to `/ports/ml-cpp-utils/vcpkg.json`

If you are updating to a new version of the upstream package, change `version` to the new value.
If the upstream version is unchanged then increment then `port-version` value.
If `port-version` is missing then add it and set it to `1` (the default is `0`).

{% highlight json %}
{
  "name": "ml-cpp-utils",
  "version": "0.1.0",
  "port-version": 2,
  "homepage": "https://github.com/nukethebees/cpp_utils",
  "license": "GPL-3.0",
  "dependencies": [
    "gtest",
    {
      "name": "vcpkg-cmake",
      "host": true
    },
    {
      "name": "vcpkg-cmake-config",
      "host": true
    }
  ]
}
{% endhighlight %}

Update the package's version and baseline using

{% highlight text %}
vcpkg --x-builtin-ports-root=./ports --x-builtin-registry-versions-dir=./versions x-add-version --all --verbose
{% endhighlight %}

If you had not previously changed `version` or `port-version` then you may need to add `--overwrite-version` to forcibly overwrite the current `port-version`. I recommend avoiding this and always incrementing the version or port version.

Commit your changes. The process is finished.

# Sources

* <https://learn.microsoft.com/en-us/vcpkg/produce/publish-to-a-git-registry>
* <https://learn.microsoft.com/en-us/vcpkg/maintainers/registries>
* <https://learn.microsoft.com/en-gb/vcpkg/troubleshoot/build-failures?WT.mc_id=vcpkg_inproduct_cli>