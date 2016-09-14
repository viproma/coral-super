Coral "super-project"
=====================
This repository contains [CMake](https://cmake.org) scripts for downloading,
building and packaging Coral and (almost) all of its dependencies in just a
few simple steps.

Specifically, there are two scripts:

  * `CMakeLists.txt`, for downloading and building the code using CMake in
    the "normal mode".
  * `make-release.cmake`, for bundling Coral and its runtime dependencies into
    a release package.  This must be run by CMake in "script mode"

The latter will, unless otherwise is specified by the user, automatically
run the former in a temporary working directory.


Requirements
------------
The CMake "super build system" described by `CMakeLists.txt` automatically
downloads and builds Coral and its dependencies by using CMake's
[ExternalProject](https://cmake.org/cmake/help/v3.0/module/ExternalProject.html)
module.  For this to work, some tools must already be installed on your system:

  * CMake (3.0 or later)
  * [Git](https://git-scm.com/)
  * [Mercurial](https://www.mercurial-scm.org/) (required by dependencies)
  * [Subversion](https://subversion.apache.org/) (required by dependencies)
  * [Boost](http://www.boost.org/) (can be downloaded automatically for Visual
    Studio; see below)
  * Java Development Kit (only required if you want to build JDSB, which
    is not done by default)

The `make-release.cmake` script has no further *mandatory* dependencies of
its own, but if you want it to create a ZIP file, you also need the Zip
program by [Info-ZIP](http://www.info-zip.org/).


Downloading and building
------------------------

The rest of this document describes how to use the `CMakeLists.txt` script,
which is what you probably want to do if you plan to participate in Coral
development.  If all you want is to *build* Coral and create a release bundle,
check out the comments at the top of [`make-release.cmake`](make-release.cmake).

  1. Clone this repository locally.  Hereafter, we refer to the topmost
     directory of the cloned repository as `SOURCE_DIR`.

  2. Create a directory for the build files.  This can be a subdirectory
     of `SOURCE_DIR`, or it can be in a completely different place.
     (Actually, it can also *be* `SOURCE_DIR`, but everyone agrees that
     this is a Bad Idea.)  Hereafter, we refer to this as `BUILD_DIR`.

  3. In a terminal/console, navigate to `BUILD_DIR` and run CMake, like so:

         cd BUILD_DIR
         cmake [options] SOURCE_DIR
         cmake --build .

     See the CMake documentation as well as the list of variables
     below for what you can put in place of `[options]`.

Options and variables
---------------------

The following variables may be defined on the CMake command line, by using
options on the form `-DVAR=value`.

  * `CORAL_GIT_REPOSITORY`: The Git repository to use for Coral.  If you intend
    to participate in Coral development, this should probably be your own
    fork of the main repository.  If not specified, this will point to
    the main repository.

  * `CORAL_GIT_TAG`: Which branch, tag or commit ID to check out from the Coral
    repository.  By default, this is `master`.

  * `DOWNLOAD_BOOST`: Whether pre-built Boost libraries should be downloaded
    from a SINTEF server.  This only works for Visual Studio builds, and by
    default it is `OFF`.

  * `BOOST_INCLUDEDIR` and `BOOST_LIBRARYDIR`: These are forwarded to CMake's
    `FindBoost` script.  Run `cmake --help-module=FindBoost` for more info.
    If `DOWNLOAD_BOOST` is `ON`, these are set automatically.

