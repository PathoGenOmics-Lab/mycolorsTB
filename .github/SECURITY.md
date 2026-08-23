# Security Policy

## What there is to attack here

mycolorsTB is an R package of colour palettes and a few plotting helpers. It
opens no network connections, writes no files, starts no processes, and runs
nothing from its input. The palettes are static character vectors of hex codes,
and the only value that comes from outside is the tree that `plot_tb_tree()` and
`plot_tb_cladogram()` hand to `ape::read.tree()`. Claiming a large attack
surface for that would be theatre.

Two things are nonetheless real, and they are what this policy is about.

**The package is on CRAN.** Users install it with
`install.packages("mycolorsTB")`, which downloads a tarball, runs R code from it
at install time and again at attach time, on whatever machine the user is
working on. That is the shortest path from a compromised release to somebody
else's session, and it does not depend on the package doing anything
interesting.

**The workflows hold a token.** The labelling workflow runs on
`pull_request_target`, which means it runs from the base branch with a
`GITHUB_TOKEN` that can write to pull requests, on a trigger that fires for
pull requests from forks. It is safe because it never checks out or executes the
pull request's code: it reads the list of changed filenames and writes labels. A
change that gives any `pull_request_target` workflow a checkout of the pull
request's branch, or that runs a script from it, is a security problem and not a
style preference.

## Reporting

Email **paula.ruiz.rodriguez@csic.es** with `mycolorsTB security` in the subject
line. Please do not open an issue: an issue is visible to everyone who can read
this repository and is indexed the moment it exists, which hands the details to
anyone watching before there is a fixed release to point at.

A useful report says what an attacker can make happen, stated as an outcome
(code running on a user's machine at install or attach time, a token reaching a
fork's code, a file written somewhere the caller did not ask for), and gives the
package version, the R version and platform from `sessionInfo()`, and the
smallest call or file that reproduces it.

Expect a first reply within about a week. This is a small academic project with
no on-call rotation, so that is an honest expectation rather than a service
level. If a week passes in silence, send the email again: the likely explanation
is that it was buried, not ignored.

Please give a fix a reasonable window before publishing details. If you intend
to disclose on a given date, say so and it will be worked to, with credit in the
release notes unless you would rather stay anonymous.

## Supported versions

| Version | Status |
|---------|--------|
| 0.1.x | supported, this is the CRAN release line |
| anything older | there is nothing older; 0.1.1 was the first CRAN release |

Fixes go into a new release on that line rather than being backported, and the
answer to "which version should I run" is the newest one on CRAN. A copy
installed from this repository with `devtools::install_github()` is the
development line: it is fine to test with, and it is not what a security fix is
announced against.

Nothing else is supported. There is no conda package, no container image and no
third-party build maintained by this project, so a copy of mycolorsTB obtained
anywhere other than CRAN or this repository is outside what can be spoken for. A
tarball whose contents do not match the corresponding tag here is exactly the
kind of thing worth reporting.

## Out of scope

A wrong colour, an unreadable label, a helper that errors on input it should
accept, or a plot with a nonsensical axis range is a correctness bug. Open a
normal issue for those. `plot_tb_tree("")` once built a plot whose axis range
came from `max()` over nothing, that is `-Inf`; that was a real defect, it was
fixed, and it was never a vulnerability.

Vulnerabilities in ggplot2, ape, ggtree or R itself belong upstream. If an
upstream advisory affects what mycolorsTB requires, an ordinary issue here is
welcome so the requirement can be adjusted.
