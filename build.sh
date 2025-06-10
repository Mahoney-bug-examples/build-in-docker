#!/usr/bin/env bash

set -eu

main() {
  local outcome=$1

  export BUILDKIT_PROGRESS=plain
  export PROGRESS_NO_TRUNC=1

  rm -rf build

  if ! docker build . --build-arg outcome="$outcome" --output build; then
    docker build . --build-arg outcome="$outcome" --target build-output --build-arg "CACHE_BUSTER=$(date +%s)" --output build
    echo "Output can be found in build"
    if [ -e build/failed ]; then
      exit "$(cat build/failed)";
    else
      echo "Docker build passed the second time! Very odd... Must be something flaky."
      exit 1
    fi
  fi
}

main "$@"
