<!--
Fill in what applies and delete what does not. A short pull request needs a
short description; nobody is asking for an essay to fix a typo.
-->

## What this changes

<!-- One or two sentences. What is different after this is merged? -->

## Why

<!-- The problem it solves. Link an issue with "Closes #123" if there is one. -->

## How it was verified

<!--
The important part, and the one a reviewer cannot reconstruct from the diff.

Not "it should work", but what you ran in R and what came back. For example: the
call you made in a fresh session with its output before and after, the palette
you rendered and looked at, or the `R CMD check` line that used to be a NOTE and
is not one any more.

Reading the code is not verification here. `view_palette()` shipped a ggplot2
aesthetic that had been deprecated since 3.4.0, and it survived because the
vignette chunk and the examples that call it were never run automatically; the
warning that reached users asked them to report the problem to us.
-->

## Checklist

- [ ] I re-ran `devtools::document()`, so `man/` and `NAMESPACE` match the roxygen comments in `R/`. <!-- Worth doing even when the change looks like comments only. Two .Rd files once shipped \dontrun{} while their roxygen source said \donttest{}, so the next person to run document() would have silently flipped CRAN from skipping those examples to running them. -->
- [ ] `devtools::check()` (or `R CMD check --as-cran`) passes with no new ERROR, WARNING or NOTE. <!-- It needs ggtree, which is on Bioconductor and not CRAN: BiocManager::install("ggtree"). -->
- [ ] I ran the examples of every function I touched in a fresh session, rather than only reading them.
- [ ] `NEWS.md` has an entry, if a user would notice this change.
- [ ] `DESCRIPTION` `Version` is bumped, if this is going to CRAN.
