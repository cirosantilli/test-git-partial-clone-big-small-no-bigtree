#!/usr/bin/env bash
rm -rf .git

set -eux

# Use random bytes to make it uncompressible on the wire, requires Python 3.9.
# https://stackoverflow.com/questions/32329381/generating-random-string-of-seedable-data/66018128#66018128
randbytes() (
  python -c 'import random;import sys;random.seed(int(sys.argv[1]));sys.stdout.buffer.write(random.randbytes(int(sys.argv[2])))' "$@"
)

rm -rf small* subdir big*

cat <<'EOF' >README.md
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
EOF

make_small() (
  n="$1"
  dir="$2"
  rm -rf "$dir"
  mkdir -p "$dir"
  tmpf="$(pwd)/tmp"
  randbytes 0 $n > "$tmpf"
  cd "$dir"
  split -a4 -b1 -d "$tmpf" ''
  cd -
  rm "$tmpf"
)
n=1000
make_small $n small
make_small $n small2
make_small $n subdir/small

make_big() (
  n="$1"
  dir="$2"
  i=0
  while [ $i -lt 10 ]; do
    randbytes "$i" 10000000 > "${dir}${i}"
    i=$(($i + 1))
  done
)
n=10
make_big "$n" 'big'
mkdir -p 'big'
make_big "$n" 'big/'

## big_tree
#mkdir -p big_tree
#cd big_tree
#python -c 'import random
#import sys
#import os
#import string
#random.seed(0)
#for i in range(1, 50000):
#    open(("".join(random.choices(string.ascii_uppercase + string.digits, k=200))), "a").close()
#'
#cd ..

git init
git remote add origin git@github.com:cirosantilli/test-git-partial-clone-big-small-no-bigtree.git
git add .
date='@0 +0000'
email=''
name='a'
commit() (
  GIT_AUTHOR_DATE="$date" \
    GIT_AUTHOR_EMAIL="$email" \
    GIT_AUTHOR_NAME="$name" \
    GIT_COMMITTER_DATE="$date" \
    GIT_COMMITTER_EMAIL="$email" \
    GIT_COMMITTER_NAME="$name" \
    git commit -m 0 "$@"
)
commit
git checkout -b bigissmall
mv big bigdir
cp -rv small big
git add .
commit
git checkout master
