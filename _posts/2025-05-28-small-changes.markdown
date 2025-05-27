---
layout: post
title:  "On small changes"
date:   2025-05-28 18:00:00 +0100
categories: programming opinion
---

I've noticed that some open source software projects dislike trivial pull requests (PR) [^1].
This may be counterproductive for technical and cultural reasons. For this argument, a trivial PR makes a very small but unambiguously positive benefit to a project e.g. a minor function optimisation.

# Culture

Getting started with large projects can be a challenge.
Potential contributors may be filtered out simply by struggling to build the project.
For those who persevere, having small PRs accepted may sustain their enthusiasm while they learn the codebase.
Many of these people may have had nothing to offer but for popular projects, it's not unthinkable that one may have become a valued contributor.

On the other hand, encouraging small PRs may attract people who just want to pad their CV/resume.
Handling a PR always takes time so a PR "value-threshold" can help filter out time wasters submitting README tweaks. Additionally, maintainers have no responsibility to build people's self confidence.

# Technical

Many hands make light work.
Individual improvements may be negligible but many will eventually be noticeable.
If a PR saves a single CPU cycle (ceteris paribus) then the project has objectively been improved.
This should be welcomed.

Making an unchanging variable immutable adds implicit documentation.
It says _"this cannot change!"_ to all future readers, lessening their mental load and making new changes easier.

A larger community of contributors may catch more bugs due to more eyes on the code.
Conversely, every PR risks introducing a bug with the likelihood increasing with each commit.
The cost of a single bug may greatly outweigh numerous small improvements.
Sufficient testing is needed to reduce this risk or else require contributors to add new tests with their PRs.

Many small PRs can make the repository's history unreadable.
PRs could be combined into single commits however this costs time for maintainers to group related PRs and merge/squash them.

# Filters

One good contributor is often more valuable than many mediocre ones.
I believe a welcoming culture has a higher chance of finding these skilled contributors than an unwelcoming one.
The question is whether our hypothetical skilled developers are actually being pushed away in reality.

The "worse is better" [^2] concept may apply too.
Software that is easy to use and implement often outcompetes technically better tools with higher barriers to entry for use and implementation.
A bad project may flourish if it can attract enough people and vice versa.

# Concluding thoughts

Accepting trivial PRs is not zero-cost. Opportunity costs are present regardless of how welcoming a project is.
Many small PRs require more manpower to handle while rejecting small PRs misses out on improvements to performance or readability and may turn away contributors who could have offered much more in future.

There is no correct answer but if I had my choice, I think I'd prefer a more welcoming culture that values small changes, even if they offer little practical benefit.

[^1]: This may apply to closed-source projects too.
[^2]: <https://en.wikipedia.org/wiki/Worse_is_better>

