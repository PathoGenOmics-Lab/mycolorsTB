# Changelog

The release notes below are the package's own `NEWS.md`, pulled into this page
at build time rather than copied. There is one list of changes and it lives in
the repository root, where `R CMD check` and CRAN read it, so this page cannot
fall behind it. Each release is a heading under this one, so both of them show
up in the table of contents on the right.

Version numbers follow CRAN's convention: 0.1.1 is the version on CRAN, and
0.1.2 is on `main` and not yet submitted. `packageVersion("mycolorsTB")` tells
you which one you have, which matters because three of the 0.1.2 changes alter
what a 0.1.1 script does: one returns different colours, and two stop with an
error where 0.1.1 quietly carried on. Those three are laid out with their old
behaviour in
[Troubleshooting](troubleshooting.md#the-same-script-gives-different-colours-than-it-used-to).

--8<-- "NEWS.md"
