# JsonStuff for GNU Octave

| WARNING: All the code in here is currently in the alpha stage. (Pre-beta, that is.) Do not use it in any production or business code! Seriously!! |
| ---- |

JSON encoding/decoding functionality for GNU Octave.

## Goals

JsonStuff attempts to provide a set of Matlab-compatible JSON encoding and decoding functions, namely `jsonencode` and `jsondecode`.

JsonStuff is currently implemented as an Octave package for the `pkg` tool. The goal for JsonStuff is to be eventually merged into core Octave. After that happens, JsonStuff will continue to be maintained as a separate package to provide support for the Octave 4.x and 5.x release lines, at least until the Octave GUI for 5.x+ is fixed for macOS.

## Soon to be Legacy

In summer 2020, core Octave implemented jsondecode and jsonencode, and these will be coming out in Octave 7.x. So JsonStuff is soon to be a legacy package, useful only for older versions of Octave. At that point I'm going to put it in "basic maintenance only" mode and stop development on it in favor of contributing to the core Octave implementations.

## Installation and usage

### Quick start

To get started using or testing this project, install it using Octave's `pkg` function:

```octave
pkg install https://github.com/apjanke/octave-jsonstuff/releases/download/v0.3.3/jsonstuff-0.3.3.tar.gz
pkg load jsonstuff
```

### Installation for development

* Clone the repo.
  * `git clone https://github.com/apjanke/octave-jsonstuff`
* Run `make dist` in a shell.
* Install the resulting `target/jsonstuff-X.Y.Z.tar.gz` package file by running `pkg install /path/to/repo/octave-jsonstuff/target/jsonstuff-X.Y.Z.tar.gz` in Octave.
* Lather, rinse, and repeat each time you make changes to any of the source code.

## Requirements

* Octave 4.4 or newer

JsonStuff runs on Octave 4.4.1 and later. It would be nice to have it work on Octave 4.0.0
and later (since Ubuntu 16 Xenial has Octave 4.0 and Ubuntu 18 Bionic has Octave 4.2); maybe we'll do that some day.

JsonStuff works on macOS, Linux, and Windows. (Though our CI is not running on Windows yet.)

## Documentation

The user documentation is in the `doc/` directory. See `doc/jsonstuff.html` or `doc/html/index.html` for
the manual.

There's a [FAQ](doc-project/FAQ.md) in `doc-project/`.

The developer documentation (for people hacking on JsonStuff itself) is in `doc-project/`. Also see
[CONTRIBUTING](CONTRIBUTING.md) if you would like to contribute to this project.

## “Internal” code

Anything in a namespace with `internal` in its name is for the internal use of this package, and is not intended for use by user code. Don't use those! Resist the urge! If you really have a use case for them, post an Issue and we'll see about making some public API for them.

## License

JsonStuff is Free Software.

The JsonStuff code itself is licensed under the GNU GPLv3.

JsonStuff includes a redistribution of the [RapidJSON](https://github.com/Tencent/rapidjson/releases) library as source code, which is licensed under the MIT License.

## Author and Support

JsonStuff is created by [Andrew Janke](https://apjanke.net).

Support is available on a best-effort basis via the [JsonStuff GitHub repo](https://github.com/apjanke/octave-jsonstuff). If you have a problem with JsonStuff, post an issue on the Issue Tracker there.

The project's author also hangs out in the `#octave` channel on [freenode IRC](https://freenode.net/) and the [Octave Maintainers mailing list](https://lists.gnu.org/mailman/listinfo/octave-maintainers). You can ask questions there.
