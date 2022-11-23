JsonStuff FAQ
=============

## Why write a new package, when there's JSONlab / JSONio / octave-rapidjson / matlab-json etc.?

I wanted a fully-fleshed out Octave package that:

* Is drop-in compatible with Matlab's `jsonencode`/`jsondecode`
* Proactively supports `string`/`datetime`/`categorical`/`table` types
* Is a full Octave Forge `pkg` package with doco and everything
* Is reasonably fast
* Experimentally supports encoding customization by user-defined classes, as a lark

So, when looking at the existing candidates:

* [JSONlab](https://github.com/fangq/jsonlab)
  * Its JSON parser is implemented in M-code, so it's going to be slow-ish and probably incorrect for complex cases.
* [JSONio](https://www.artefact.tk/software/matlab/jsonio/)
  * Minimal docs.
  * It's built as MEX files, which I'm leery of running under Octave.
* [octave-rapidjson](https://github.com/Andy1978/octave-rapidjson)
  * Isn't type-complete
    * Doesn't support Octave objects
    * Doesn't support integers
    * I can't tell if it supports N-D arrays
* [matlab-json](https://github.com/christianpanton/matlab-json)
  * Doesn't look type-complete
    * Doesn't support objects
    * Doesn't look like it supports the nested-array form of N-D arrays
* None of them are drop-in `jsonencode`/`jsondecode` API compatible (though JSONio is close)
* None of them look with Octave `pkg` or have Octave-compatible doco or Octave Forge metadata

Plus I just wanted the experience of doing the implementation.
