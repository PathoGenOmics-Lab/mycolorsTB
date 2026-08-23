---
title: Changelog
---

The release notes below are the package's own `NEWS.md`, pulled into this page
at build time rather than copied. There is one list of changes and it lives in
the repository root, where `R CMD check` and CRAN read it, so this page cannot
fall behind it.

Version numbers follow CRAN's convention: 0.1.1 is the version on CRAN, and
0.1.2 is on `main` and not yet submitted. `packageVersion("mycolorsTB")` tells
you which one you have, which matters because three of the 0.1.2 changes alter
what working code returns rather than raising an error. Those three are laid
out with their old behaviour in
[Troubleshooting](troubleshooting.md#the-same-script-gives-different-colours-than-it-used-to).

--8<-- "NEWS.md"
