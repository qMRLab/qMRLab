#!/bin/bash
#
# Test wrapper for Octave tests.
#
# This exists because Octave's runtests() does not return an error status, so
# you can't detect within octave whether your tests have failed.
#
# This must be run from the root of the repo.
#
# Prerequisite: "make local"

set -e

package=$(grep "^Name: " DESCRIPTION | cut -f2 -d' ')

OCTAVE="octave --no-gui --norc"

test_dir="$1"

tempfile=$(mktemp /tmp/octave-${package}-tests-XXXXXXXX)
if [[ "$test_dir" == "" ]]; then
  ${OCTAVE} --path="$PWD/inst" --eval="runtests" 2>&1 | tee "$tempfile"
else
  ${OCTAVE} --path="$PWD/inst" --eval="addpath('$test_dir'); runtests $test_dir" 2>&1 | tee "$tempfile"
fi

if grep FAIL "$tempfile" &>/dev/null; then
  echo runtests.sh: Some tests FAILED!
  status=1
else
  echo runtests.sh: All tests passed.
  status=0
fi

rm "$tempfile"
exit $status