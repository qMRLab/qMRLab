# JsonStuff Developer Notes

## Build and CI

### Environments

| OS | Environment | OS Version           | Octave | jsoncpp | Texinfo | Qt | Comments |
| -- | ----------- | -------------------- | ------ | ----- |------- | ----- | -------- |
| Ubuntu | Bionic     | 18 Bionic         | 4.2.2  | 1.7   | 6.5    | 5.9   | No Travis env yet |
| Ubuntu | Xenial     | 16 Xenial         | 4.0    | 1.7   | 6.1    | 5.5   |       |
| Ubuntu | Trusty     | 14 Trusty         | 3.8    | 0.6   | 5.2    | 5.2   |       |
| macOS | xcode10.1   | 10.13 High Sierra |        |       | 4.8    |       |       |
| macOS | xcode10     | 10.13 High Sierra |        |       | 4.8    |       |       |
| macOS | xcode9.4    | 10.13 High Sierra |        |       | 4.8    |       |       |
| macOS | xcode9.2    | 10.12 Sierra      |        |       | 4.8    |       |       |
| macOS | Homebrew (1/2019) | 10.13+      | 4.4    | 1.8   | 6.5    | 5.12  |       |

Texinfo version is the system version on Mac, except in the "Homebrew" environment. Homebrewed versions are all up to date on macOS, so I'm not bothering listing them.

I'm assuming Ubuntu stays on the same major/minor version for its packages within a release.

We currently require:

| Package   | Version | Why                     |
| --------- | ------- | ----------------------- |
| Texinfo   | 5.x     | Supports auto-numbering |
| Octave    | 4.4.1   | This is the last version whose macOS GUI works |
| RapidJSON | 1.1     | This was the current version when we migrated to RapidJSON |

## Release checklist

* Double-check the version numbers:
  * in `DESCRIPTION` and `.travis.yml`
* Update the version in the URL in installation instructions in `README.md`
* Update the Date in `DESCRIPTION`
* Commit the above changes with comment 'vX.Y.Z'
* Run tests
* `git tag vX.Y.Z`
* `git push; git push --tags`
* Draft the release on GitHub
* `make dist` and upload the tarball as a file for the release
* Open development on new version
  * Update the version numbers 
    * in `DESCRIPTION` and `.travis.yml`
    * do *not* update the URL in the installation instructions in `README.md`
  * `git commit -a -m "Open development on vX.Y.Z"; git push`
