> MELPA came along and destroyed the versioning scheme. Still kind of mad about that.
>
> &mdash; <cite>Someone with the handle "/u/tromey" claiming to be the author of `package.el`.</cite>

# shmelpa

![harmony](harmony.png "Version Harmony With GNU Elpa")
*Left-frame melpa versions bear no relation to gnu's.  Right-frame shmelpa versions dovetail.*

## Frequently Asked Questions

### Why?

The ``package-install`` command will generally not update a bumped package dependency because MELPA's datetime versioning is incompatible with the semantic version numbers in `Package-Requires` clauses (the Schism).

The particulars of the Schism are expatiated in uninteresting detail in [Issue 2944](https://github.com/melpa/melpa/issues/2944).

### How can I try it out?

Comment out the `add-to-list` of melpa, and add to `.emacs`:

```
;;; (add-to-list 'package-archives
;;;   '("melpa" . "https://melpa.org/packages/"))

(add-to-list 'package-archives
  '("shmelpa" . "https://shmelpa.commandlinesystems.com/packages/"))
```

If you don't comment out the melpa line, MELPA's numerically greater versions will mask shmelpa's lowly semantic versions.

### Where is package XYZ?

It's currently tagged in your `package-user-dir` with MELPA's ginormous major version (a number greater than 20 million!).  Thus `M-x package-list-packages` won't show shmelpa's single-digit major version, deeming it woefully obsolete.  `RET` into the package's *installed* line item, and you should see shmelpa in "Other versions".

### What does shmelpa stand for?

"shmelpa" is not an acronym but rather [shm-reduplication](https://en.wikipedia.org/wiki/Shm-reduplication) of its predecessor.
