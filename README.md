DSB development environment
===========================
This repository contains a CMake script which downloads and builds DSB *and
its dependencies* in just a few simple steps.  It achieves this by using
CMake's ExternalProject module.  You are still required to manually download
and install some tools and dependencies, though:

  * Git (to check out this repository and others)
  * CMake (3.0 or later)
  * Mercurial (required by dependencies)
  * Subversion (required by dependencies)
  * Boost (not covered by this script because it's so friggin' big)
  * Java Development Kit (only required if you want to build JDSB, which
    is not done by default)


Step-by-step procedure
----------------------

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
(To be added)
