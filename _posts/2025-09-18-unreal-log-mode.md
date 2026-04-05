---
layout: post
title:  "Changing Unreal 5's logging verbosity"
date:   2025-09-18 11:30:00 +0100
categories: software c++ unreal
---

In Unreal 5, you can temporarily change the logging verbosity for a category using the `log` command in the editor's command line.

```text
log <category> <verbosity>
```

e.g.

```text
>>> log LogTemp verbose
Cmd: log LogTemp verbose
LogHAL: Log category LogTemp verbosity has been raised to Verbose.
LogTemp                                   Verbose  
```


If you wish to change it at startup, use the `-LogCmds` command line argument.
You can specify multiple settings using a comma as a delimiter.

```text
 -LogCmds="<category> <verbosity>, ..."  
```

e.g.

```text
 -LogCmds="LogTemp Verbose"  
```