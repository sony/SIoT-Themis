#!/bin/sh
set -e

if [ ! -d "externals" ]; then
  git submodule init
else
  echo "externals already exists, skipping git submodule init"
fi

git submodule update