# Test Git Partial Clone Big Small No Big Tree

This repo is a stress test to check if we are able to download only certain files or directories from a git repository: https://stackoverflow.com/questions/600079/how-do-i-clone-a-subdirectory-only-of-a-git-repository/52269934#52269934

This repo is the same as https://github.com/cirosantilli/test-git-partial-clone-big-small but without the `big_tree` subdirectory which we don't currently know how to not download.

This repo is designed such that if you clone anything outside of [small/](small/) or [small2/](small2/) or [subdir/small/](subdir/small/), then you get at least 100 MB extra pseudorandom data, so it will be very noticeable on the network and disk usage.

Contents:

* [big/](big/): 10x pseudorandom 10 MB files (~100 MB), small filenames
* [big0](big0) - [big9](big9): 10x pseudorandom 10 MB files (~100 MB). These were added to ensure that toplevel objects are not fetched.
* [small/](small/): 1000x 1 B files, small filenames. The usual download target.
* [small2/](small2/): same as [small/](small/). To see if the method supports downloading multiple directories at once together with `small`
* [subdir/small/](subdir/small/): same as [small/](small/). Because `git sparse-checkout set --no-cone small` works on basenames not full paths and also fetches [subdir/small/](subdir/small/), for full paths you need `/small`

There is also a branch `bigissmall` in which:

* `big/` is renamed to `bigdir/`
* `small/` is renamed to `big/`

to check that cloning from a different branch does not touch `master` in any way.

This repository is automatically generated with the [generate.sh](generate.sh) script. Just run:

```
./generate.sh
```

and it will nuke your old `.git` and create a clean new repo.
