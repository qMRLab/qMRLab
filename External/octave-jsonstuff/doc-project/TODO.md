JsonStuff TODO
==============

## Big things

* Unify `make local` target and `src/Makefile`

## Code

* Tests
* jsondecode
  * Extension: field-filling for arrays of objects -> struct array instead of cell array of structs
* jsonencode
  * Maybe support Java objects in inputs?
* Other TODOs scattered around the code
* Maybe OOP-ify the code (keeping `jsonencode`/`jsondecode`) as front-end function wrappers
  * So I can support various encoding/decoding options
* Maybe [UBJSON](https://en.wikipedia.org/wiki/UBJSON) support
* Maybe octfile-ify jsonencode, for speed

## Project

* Get TravisBuddy working
* Travis build
  * Try Docker for installing 4.4 on Linux: https://github.com/mtmiller/octave-snapshot
  * Get Octave working on Windows Travis env
* Add a `make dist-local` target that copies currently-changed files instead of extracting from git history
