Coral "super-project"
=====================
This repository contains [CMake](https://cmake.org) scripts for downloading,
building and packaging [Coral](https://github.com/viproma/coral),
[JCoral](https://github.com/viproma/jcoral) and (almost) all of their
dependencies in just a few simple steps.

Specifically, there are two scripts:

  * `CMakeLists.txt`, for downloading and building the code using CMake in
    the "normal" way.

  * `make-release.cmake`, for bundling Coral, JCoral and their runtime
    dependencies into release packages.  This must be run by CMake in
    "script mode".

The latter will, unless otherwise is specified by the user, automatically
run the former in a temporary working directory.


Requirements
------------
The CMake "super build system" described by `CMakeLists.txt` automatically
downloads and builds Coral and most of its dependencies by using CMake's
[ExternalProject](https://cmake.org/cmake/help/v3.0/module/ExternalProject.html)
module.  There are some tools and libraries which must already be installed
on your system, however:

  * CMake (3.0 or later)
  * [Git](https://git-scm.com/)
  * [Mercurial](https://www.mercurial-scm.org/) (required by dependencies)
  * [Subversion](https://subversion.apache.org/) (required by dependencies)
  * [Boost](http://www.boost.org/)

In principle, we could download and build Boost like all the other dependencies,
but it's so big, and takes so long to compile, that you probably wouldn't want
that.  Most Linux distros let you install Boost easily through their package
managers, and you'll find [Windows binaries available for download](
https://sourceforge.net/projects/boost/files/boost-binaries/) on the web.

The `make-release.cmake` script has no further *mandatory* dependencies of
its own, but if you want it to bundle everything into an archive file (e.g.
ZIP), you need the appropriate programs for it.


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

You'll now find the Coral source in a local Git repository under
`BUILD_DIR/coral-prefix/src/coral`, and the generated project files or
Makefiles under `BUILD_DIR/coral-prefix/src/coral-build`.


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

  * `CORAL_INSTALL_PREFIX`: Where to install Coral when the `install` target is
    built.

  * `BUILD_JCORAL`: Whether to also download and build the JCoral library.

  * `JCORAL_GIT_REPOSITORY`, `JCORAL_GIT_TAG`, `JCORAL_INSTALL_PREFIX`: Same
    as the corresponding `CORAL_*` variables, but for JCoral. Only used when
    `BUILD_JCORAL` is `TRUE`.

  * `DEPENDENCY_INSTALL_PREFIX`: Where to install the dependencies when the
    `install` target is built.

  * `INSTALL_DEBUG_RUNTIME_LIBRARIES`: Whether to install the debug versions of
    system runtime libraries along with other dependencies. (Currently only
    applicable to the MSVC toolchain.)

  * `BOOST_ROOT`, `BOOST_INCLUDEDIR` and `BOOST_LIBRARYDIR`:
    These are forwarded to the Coral build scripts and thereafter used by
    CMake's `FindBoost` script.  Run `cmake --help-module FindBoost` for more
    info.

  * `CORAL_BUILD_PRIVATE_API_DOCS`, `CORAL_BUILD_TESTS`,
    `CORAL_ENABLE_DEBUG_LOGGING` and `CORAL_ENABLE_TRACE_LOGGING`:
    These are forwarded to Coral's build scripts and affect how Coral is
    built.  See Coral's CMakeLists.txt for more information.
