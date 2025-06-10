#!/usr/bin/env bash
set -euo pipefail

cacheDir=~/.build/cache
depFile="$cacheDir/build_dep.txt"
buildDir=build

main() {

  local outcome=$1

  if ! containsElement "--offline" "$@"; then
    populateDependencyCache
  fi

  if ! containsElement "--dry-run" "$@"; then
    build "$outcome"
  fi
}

populateDependencyCache() {
  mkdir -p "$cacheDir"
  if ! [[ -f "$depFile" ]]; then
    curl -sS --fail-with-body https://example.com > "$depFile"
    echo "Downloaded dependency"
  else
    echo "Dependency already present"
  fi
}

build() {

  local outcome=$1

  if ! [[ -f "$depFile" ]]; then
    echo>&2 "MISSING DEPENDENCIES!"
  fi


  if [[ "$outcome" == fail ]]; then
    mkdir -p "$buildDir/test-results"
    cat > "$buildDir/test-results/test.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites time="15.682687">
    <testsuite name="Tests.Authentication" time="9.076816">
        <testcase name="testCase9" classname="Tests.Authentication" time="0.982">
            <failure message="Assertion error message" type="AssertionError">
            </failure>
        </testcase>
    </testsuite>
</testsuites>
EOF
    echo>&2 "There were test failures"
    return 1
  else
    mkdir -p "$buildDir/artifacts"
    echo "SUCCESS" > "$buildDir/artifacts/outcome.txt"
  fi
}

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

main "$@"
