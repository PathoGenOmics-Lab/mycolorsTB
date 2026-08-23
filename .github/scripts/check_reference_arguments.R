#!/usr/bin/env Rscript

# Check docs/reference.md against the installed package's formals().
#
# WHY THIS EXISTS
#
# The reference page on the documentation site is hand-written prose. That was a
# deliberate choice: the .Rd files say what the arguments are, and the page is
# meant to say what they are for, which is not the same document and does not
# come out well when one is generated from the other. The cost of that choice is
# that the page can go stale without anyone noticing, and the specific way it
# goes stale is an argument. Renaming `palette_name`, adding an argument to
# view_palette(), or dropping one from plot_tb_tree() leaves prose that still
# reads perfectly and is quietly wrong. This package has already lived through a
# smaller version of that: in 0.1.1 the four scale_* functions took no arguments
# at all, and in 0.1.2 they take `...`.
#
# So the prose stays hand-written, and this script holds the one part of it that
# has a right answer. It reads the page, finds the signature the page states for
# each exported function, and compares the argument names, in order, against
# formals() of the package installed from the same checkout. Everything else on
# the page, every sentence about what an argument means, is left alone.
#
# WHAT IT EXPECTS OF THE PAGE
#
#   1. Every export has a section. A heading at any level is a section for an
#      export when the export's name appears in it as a whole word, so
#      `## tb_palette()`, `## The tb_palette() function` and
#      `## scale_color_mycolors() and scale_fill_mycolors()` all count, and the
#      last one opens a section for both.
#
#   2. Every exported *function* states its signature somewhere in one of its
#      sections. A signature is any call written out with its arguments named
#      rather than filled in: `tb_palette(n, palette_name = "classicTB")` is one,
#      `tb_palette(8)` is not, and both may appear on the page. The call may be
#      written inline, in a fenced block, split over several lines, and with or
#      without a `mycolorsTB::` prefix.
#
#      A section may hold several calls and only one of them needs to be the
#      signature: examples are read and then set aside, because their arguments
#      are values rather than names. The check fails when *no* call in the
#      section lists exactly the arguments the function has.
#
#   3. The three exported palettes, `mycolors`, `classicTB` and `pathogenomics`,
#      are data and have no formals. They need a section and nothing more.
#
# WHAT IT DELIBERATELY DOES NOT CHECK
#
# Defaults, types, return values and every word of the prose. A default that
# changes is a change to behaviour and belongs in NEWS.md and in the changelog
# page, where a reader will look for it; an argument that changes name is a
# change to the page's correctness, and nothing else would catch it.
#
# USAGE
#
#   Rscript .github/scripts/check_reference_arguments.R [path/to/reference.md]
#
# Default path is docs/reference.md, resolved from the repository root. The
# package must be installed and loadable. Exit status 0 when the page agrees
# with the package, 1 when it does not.

PACKAGE <- "mycolorsTB"

args <- commandArgs(trailingOnly = TRUE)
reference_path <- if (length(args) >= 1L) args[[1L]] else "docs/reference.md"

if (!file.exists(reference_path)) {
  stop("reference page not found: ", reference_path, call. = FALSE)
}
if (!requireNamespace(PACKAGE, quietly = TRUE)) {
  stop("package not installed: ", PACKAGE, call. = FALSE)
}

# ---------------------------------------------------------------- text pieces

# Split a string into single characters once, rather than substring() in a loop.
chars_of <- function(text) strsplit(text, "", fixed = TRUE)[[1L]]

# Walk from an opening parenthesis to the one that closes it, ignoring anything
# inside a quoted string. R's own strings can be double, single or backtick
# quoted and all three can carry a backslash escape, so all three are tracked.
close_paren <- function(chars, open_at) {
  depth <- 0L
  quote_char <- ""
  i <- open_at
  n <- length(chars)
  while (i <= n) {
    ch <- chars[[i]]
    if (nzchar(quote_char)) {
      if (ch == "\\") {
        i <- i + 2L
        next
      }
      if (ch == quote_char) quote_char <- ""
    } else if (ch == "\"" || ch == "'" || ch == "`") {
      quote_char <- ch
    } else if (ch == "(" || ch == "[" || ch == "{") {
      depth <- depth + 1L
    } else if (ch == ")" || ch == "]" || ch == "}") {
      depth <- depth - 1L
      if (depth == 0L) return(i)
    }
    i <- i + 1L
  }
  NA_integer_
}

# Split an argument list on the commas that belong to it, leaving alone the ones
# inside a nested call, a vector or a string.
split_arguments <- function(text) {
  chars <- chars_of(text)
  if (length(chars) == 0L) return(character(0))
  parts <- character(0)
  start <- 1L
  depth <- 0L
  quote_char <- ""
  i <- 1L
  while (i <= length(chars)) {
    ch <- chars[[i]]
    if (nzchar(quote_char)) {
      if (ch == "\\") {
        i <- i + 2L
        next
      }
      if (ch == quote_char) quote_char <- ""
    } else if (ch == "\"" || ch == "'" || ch == "`") {
      quote_char <- ch
    } else if (ch == "(" || ch == "[" || ch == "{") {
      depth <- depth + 1L
    } else if (ch == ")" || ch == "]" || ch == "}") {
      depth <- depth - 1L
    } else if (ch == "," && depth == 0L) {
      parts <- c(parts, paste(chars[start:(i - 1L)], collapse = ""))
      start <- i + 1L
    }
    i <- i + 1L
  }
  c(parts, paste(chars[start:length(chars)], collapse = ""))
}

# The name in front of the first top level `=`, or the whole part when there is
# no default. Returns NA when the part is not an argument name at all, which is
# how an example call gets told apart from a signature: in `tb_palette(8)` the
# part is `8`, and in `view_palette("mycolors")` it is a string.
argument_name <- function(part) {
  chars <- chars_of(part)
  depth <- 0L
  quote_char <- ""
  cut <- NA_integer_
  i <- 1L
  while (i <= length(chars)) {
    ch <- chars[[i]]
    if (nzchar(quote_char)) {
      if (ch == "\\") {
        i <- i + 2L
        next
      }
      if (ch == quote_char) quote_char <- ""
    } else if (ch == "\"" || ch == "'" || ch == "`") {
      quote_char <- ch
    } else if (ch == "(" || ch == "[" || ch == "{") {
      depth <- depth + 1L
    } else if (ch == ")" || ch == "]" || ch == "}") {
      depth <- depth - 1L
    } else if (ch == "=" && depth == 0L) {
      # `==`, `<=`, `>=` and `!=` are comparisons, not defaults.
      before <- if (i > 1L) chars[[i - 1L]] else ""
      after <- if (i < length(chars)) chars[[i + 1L]] else ""
      if (!(before %in% c("<", ">", "!", "=")) && after != "=") {
        cut <- i
        break
      }
    }
    i <- i + 1L
  }
  name <- if (is.na(cut)) part else paste(chars[seq_len(cut - 1L)], collapse = "")
  name <- trimws(name)
  name <- gsub("^`|`$", "", name)
  if (name == "...") return("...")
  if (grepl("^[A-Za-z.][A-Za-z0-9._]*$", name)) name else NA_character_
}

# --------------------------------------------------------- reading the page

lines <- readLines(reference_path, warn = FALSE)
document <- paste(lines, collapse = "\n")
document_chars <- chars_of(document)
# Offset of the first character of each line, so a match position can be
# reported as a line number.
line_starts <- cumsum(c(1L, nchar(lines) + 1L))[seq_along(lines)]

line_of <- function(offset) sum(line_starts <= offset)

heading_lines <- integer(0)
heading_match <- regmatches(lines, regexec("^(#{1,6})[ \t]+(.*?)[ \t]*#*$", lines))
headings <- list()
for (i in seq_along(lines)) {
  m <- heading_match[[i]]
  if (length(m) == 0L) next
  words <- gsub("`", "", m[[3L]], fixed = TRUE)
  words <- strsplit(words, "[^A-Za-z0-9._]+")[[1L]]
  heading_lines <- c(heading_lines, i)
  headings[[length(headings) + 1L]] <- list(
    line = i, level = nchar(m[[2L]]), text = m[[3L]], words = words[nzchar(words)]
  )
}

# A section runs from its heading to the next heading at the same level or above.
section_text <- function(index) {
  this <- headings[[index]]
  end <- length(lines)
  for (j in seq_along(headings)) {
    if (j <= index) next
    if (headings[[j]]$level <= this$level) {
      end <- headings[[j]]$line - 1L
      break
    }
  }
  from <- this$line
  list(text = paste(lines[from:end], collapse = "\n"), offset = line_starts[[from]])
}

# ------------------------------------------------------ finding the signatures

# Every call to `name` written out in `text`, as a list of argument name vectors.
# A call whose arguments are values rather than names is dropped here, which is
# what leaves examples out of the comparison.
calls_in <- function(text, offset, name, heading_lines) {
  pattern <- sprintf(
    "(?<![A-Za-z0-9._])(?:%s::)?%s[ \t\n]*\\(", PACKAGE,
    gsub(".", "\\.", name, fixed = TRUE)
  )
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (matches[[1L]] == -1L) return(list())

  chars <- chars_of(text)
  found <- list()
  for (k in seq_along(matches)) {
    open_at <- matches[[k]] + attr(matches, "match.length")[[k]] - 1L
    close_at <- close_paren(chars, open_at)
    if (is.na(close_at)) next
    inside <- if (close_at - open_at <= 1L) {
      ""
    } else {
      paste(chars[(open_at + 1L):(close_at - 1L)], collapse = "")
    }
    parts <- split_arguments(inside)
    parts <- parts[nzchar(trimws(parts))]
    names_found <- vapply(parts, argument_name, character(1L), USE.NAMES = FALSE)
    if (anyNA(names_found)) next
    at_line <- line_of(offset + matches[[k]] - 1L)
    # `## view_palette()` in a heading names the function; it does not claim the
    # function takes nothing. Written with arguments, a heading is a signature
    # like any other and is read as one.
    if (length(names_found) == 0L && at_line %in% heading_lines) next
    found[[length(found) + 1L]] <- list(
      arguments = names_found,
      line = at_line,
      written = gsub("[ \t\n]+", " ", paste(chars[open_at:close_at], collapse = ""))
    )
  }
  found
}

common_prefix <- function(a, b) {
  n <- min(length(a), length(b))
  if (n == 0L) return(0L)
  same <- a[seq_len(n)] == b[seq_len(n)]
  if (all(same)) n else which(!same)[[1L]] - 1L
}

signature_of <- function(name, arguments) {
  sprintf("%s(%s)", name, paste(arguments, collapse = ", "))
}

# ------------------------------------------------------------------ the check

exports <- sort(getNamespaceExports(PACKAGE))
namespace <- asNamespace(PACKAGE)
problems <- character(0)
checked <- 0L

for (name in exports) {
  documented <- Filter(function(i) name %in% headings[[i]]$words, seq_along(headings))

  if (length(documented) == 0L) {
    problems <- c(problems, sprintf(
      paste0("%s is exported by %s and has no section in %s.\n",
             "    Add a heading whose text contains %s, for example \"## %s\"."),
      name, PACKAGE, reference_path, name, name))
    next
  }

  object <- get(name, envir = namespace)
  if (!is.function(object)) {
    # Data. A section is the whole requirement; there are no arguments to drift.
    checked <- checked + 1L
    next
  }

  expected <- names(formals(object))
  if (is.null(expected)) expected <- character(0)

  candidates <- list()
  for (i in documented) {
    section <- section_text(i)
    candidates <- c(candidates, calls_in(section$text, section$offset, name, heading_lines))
  }

  if (length(candidates) == 0L) {
    where <- paste(vapply(documented, function(i) sprintf("line %d", headings[[i]]$line),
                          character(1L)), collapse = ", ")
    problems <- c(problems, sprintf(
      paste0("%s() has a section in %s (%s) but the page never writes out its\n",
             "    signature, so there is nothing to compare against.\n",
             "    The package says   %s\n",
             "    Write that call into the section, with the arguments named rather\n",
             "    than filled in. Example calls do not count: their arguments are values."),
      name, reference_path, where, signature_of(name, expected)))
    next
  }

  if (any(vapply(candidates, function(c) identical(c$arguments, expected), logical(1L)))) {
    checked <- checked + 1L
    next
  }

  # Report against whichever call on the page comes closest, so the message
  # points at the argument that moved rather than at the whole list. Ties on the
  # matching prefix go to the longer argument list, because a call that lists
  # more of them is more likely to be the signature and less likely to be a
  # shorthand the prose used in passing.
  prefix <- vapply(candidates, function(c) common_prefix(c$arguments, expected), integer(1L))
  count <- vapply(candidates, function(c) length(c$arguments), integer(1L))
  best <- candidates[[order(-prefix, -count)[[1L]]]]
  position <- common_prefix(best$arguments, expected) + 1L
  page_says <- if (position <= length(best$arguments)) {
    sprintf("'%s'", best$arguments[[position]])
  } else {
    "nothing, the list ends"
  }
  package_says <- if (position <= length(expected)) {
    sprintf("'%s'", expected[[position]])
  } else {
    "nothing, the list ends"
  }
  problems <- c(problems, sprintf(
    paste0("%s() does not match the installed package.\n",
           "    the page says      %s%s   (%s line %d)\n",
           "    the package says   %s\n",
           "    First disagreement at argument %d: the page says %s, the package says %s."),
    name,
    name, best$written, reference_path, best$line,
    signature_of(name, expected),
    position, page_says, package_says))
}

if (length(problems) > 0L) {
  cat(sprintf("The hand-written reference has drifted from %s %s.\n\n",
              PACKAGE, as.character(utils::packageVersion(PACKAGE))))
  for (p in problems) cat(sprintf("  %s\n\n", p))
  cat(sprintf("%d of %d exports agree with the package.\n", checked, length(exports)))
  quit(status = 1L)
}

cat(sprintf("%s %s: all %d exports are documented in %s and every signature agrees.\n",
            PACKAGE, as.character(utils::packageVersion(PACKAGE)),
            length(exports), reference_path))
