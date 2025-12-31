---
layout: post
title:  "Configure existing GitHub Pages environment on Ubuntu 24.04 and WSL"
date:   2025-12-31 13:09:00 +0100
categories: blogging
---

This post contains setup instructions for initialising my GitHub pages environment so I don't have to keep relearning it.
At the time of writing I use Ubuntu 24.04 via Windows Subsystem for Linux (WSL).
Links are provided at the end for each resource I have used.

Install WSL[^1]:

{% highlight powershell %}
wsl.exe --install 
{% endhighlight %}

Get a list of existing Linux distributions available via WSL:

{% highlight powershell %}
> wsl --list --online
The following is a list of valid distributions that can be installed.
Install using 'wsl.exe --install <Distro>'.

NAME                            FRIENDLY NAME
Ubuntu                          Ubuntu
Ubuntu-24.04                    Ubuntu 24.04 LTS
openSUSE-Tumbleweed             openSUSE Tumbleweed
openSUSE-Leap-16.0              openSUSE Leap 16.0
SUSE-Linux-Enterprise-15-SP7    SUSE Linux Enterprise 15 SP7
SUSE-Linux-Enterprise-16.0      SUSE Linux Enterprise 16.0
kali-linux                      Kali Linux Rolling
Debian                          Debian GNU/Linux
AlmaLinux-8                     AlmaLinux OS 8
AlmaLinux-9                     AlmaLinux OS 9
AlmaLinux-Kitten-10             AlmaLinux OS Kitten 10
AlmaLinux-10                    AlmaLinux OS 10
archlinux                       Arch Linux
FedoraLinux-43                  Fedora Linux 43
FedoraLinux-42                  Fedora Linux 42
Ubuntu-20.04                    Ubuntu 20.04 LTS
Ubuntu-22.04                    Ubuntu 22.04 LTS
OracleLinux_7_9                 Oracle Linux 7.9
OracleLinux_8_10                Oracle Linux 8.10
OracleLinux_9_5                 Oracle Linux 9.5
openSUSE-Leap-15.6              openSUSE Leap 15.6
SUSE-Linux-Enterprise-15-SP6    SUSE Linux Enterprise 15 SP6
{% endhighlight %}

Install Ubuntu.

{% highlight powershell %}
> wsl --install Ubuntu-24.04
{% endhighlight %}

Load your WSL environment and clone your GitHub pages git repo.

{% highlight bash %}
git clone https://github.com/nukethebees/nukethebees.github.io.git
{% endhighlight %}

Install Jekyll's dependencies[^2].

{% highlight bash %}
sudo apt-get install ruby-full build-essential zlib1g-dev
{% endhighlight %}

Set a local gem installation directory.

{% highlight bash %}
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
{% endhighlight %}

Install Jekyll and Bundler.

{% highlight bash %}
gem install jekyll bundler
{% endhighlight %}

Install the required gems for your site via bundler[^3].

{% highlight bash %}
bundle install
{% endhighlight %}

Navigate to your page's local repository and run the site locally[^4]:

{% highlight bash %}
bundle exec jekyll serve
{% endhighlight %}

[^1]: <https://learn.microsoft.com/en-us/windows/wsl/install>
[^2]: <https://jekyllrb.com/docs/installation/ubuntu/>
[^3]: <https://stackoverflow.com/questions/41211670/rails-i-installed-ruby-now-bundle-install-doesnt-work>
[^4]: <https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll>