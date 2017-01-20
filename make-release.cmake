# This script creates a release bundle.
#
# USAGE
#
#   cmake -Dvar1=value1 -Dvar2=value2 -P make-release.cmake
#
# Note that the -P switch that specifies the script file MUST come after the
# -D switches that define variables.
#
# In its final step, creating the package file, the script requires that the
# appropriate programs are in the executable search path (PATH).  For the "zip"
# packager this is the Info-ZIP archiver, for "tar" it is, well, tar, and for
# "tgz" and "tbz" it is tar in conjunction with gzip or bzip2, respectively.
# On Linux, these programs are often installed by default, and if not, they can
# easily be installed through most distributions' package management systems.
# On Windows, one can use Cygwin or download Info-ZIP from
# http://www.info-zip.org.  Alternatively, this step can be disabled entirely
# by setting the 'packager' variable to "none".
#
# The release bundles will be placed in the "releases" directory.
#
#
# REQUIRED VARIABLES
#
#   releaseName         A name for the release, typically a version number or
#                       commit hash.
#
# OPTIONAL VARIABLES
#
#   binaryDir           The path to an existing CMake binary directory from
#                       which to  build the software.  If this is not specified,
#                       the script will perform the CMake generation step in
#                       a temporary working directory.
#
#   configuration       The build configuration that should be used.  The
#                       default value is "Release".  For single-configuration
#                       generators, this is used in the generation step (and
#                       thus ignored if 'binaryDir' is given), while for
#                       multi-configuration generators it is used in the build
#                       step.
#
#   packager            How (and whether) to package the files. May be "zip",
#                       "tar", "tgz", "tbz" or "none". The default is "zip" on
#                       Windows and "tgz" on *NIX.
#
#   generator           Which CMake generator to use.  Ignored if 'binaryDir'
#                       is given.
#
# FORWARDED VARIABLES
#
# These variables will be automatically forwarded to CMake during the
# generation step if they are defined.
#
#   BOOST_INCLUDEDIR
#   BOOST_LIBRARYDIR
#   DOWNLOAD_BOOST
#   CORAL_GIT_REPOSITORY
#   CORAL_GIT_TAG
#
cmake_minimum_required(VERSION 3.0.0)

# ------------------------------------------------------------------------------
# Executes a process and terminates the script if it fails.
# Usage:
#   executeProcess(<program> [arg1 [arg2 ...]] [WORKING_DIRECTORY <dir>])
function(executeProcess progName)
    execute_process(
        COMMAND "${progName}" ${ARGN}
        RESULT_VARIABLE exitCode
    )
    if(NOT (exitCode EQUAL 0))
        message(FATAL_ERROR "${progName} terminated with exit status ${exitCode}")
    endif()
endfunction()
# ------------------------------------------------------------------------------


set(packageName "coral")
set(releaseDir "releases")
set(forwardedVariables
    BOOST_INCLUDEDIR
    BOOST_LIBRARYDIR
    DOWNLOAD_BOOST
    CORAL_GIT_REPOSITORY
    CORAL_GIT_TAG
)

if((NOT DEFINED releaseName) OR (releaseName STREQUAL ""))
    message(FATAL_ERROR "'releaseName' variable not defined")
endif()
set(baseName "${packageName}_${releaseName}")


# GENERATION STEP

if((NOT DEFINED configuration) OR (configuration STREQUAL ""))
    set(configuration "Release")
endif()

if((NOT DEFINED binaryDir) OR (binaryDir STREQUAL ""))
    set(binaryDir "${releaseDir}/temp/${baseName}-${configuration}")

    unset(forwardedVariablesArgs)
    foreach(fv IN LISTS forwardedVariables)
        if(DEFINED ${fv})
            list(APPEND forwardedVariablesArgs "-D${fv}=${${fv}}")
        endif()
    endforeach()
    if(generator)
        set(generatorArgs "-G" "${generator}")
    endif()

    file(MAKE_DIRECTORY "${binaryDir}")
    executeProcess("${CMAKE_COMMAND}"
            ${generatorArgs}
            ${forwardedVariablesArgs}
            "-DCMAKE_BUILD_TYPE=${configuration}"
            "${CMAKE_CURRENT_LIST_DIR}"
        WORKING_DIRECTORY "${binaryDir}"
    )
endif()


# COMPILATION STEP

executeProcess("${CMAKE_COMMAND}"
    "--build" "${binaryDir}"
    "--config" "${configuration}"
)


# BUNDLE CREATION STEP

set(targetDir "${releaseDir}/${baseName}")
if(WIN32)
    set(dlDir "bin")
    set(dlExt ".dll")
    set(exeExt ".exe")
else()
    set(dlDir "lib")
    set(dlExt ".so*")
    set(exeExt "")
endif()

# Copy Coral files
file(INSTALL "${binaryDir}/install/coral/"
    DESTINATION "${targetDir}"
    USE_SOURCE_PERMISSIONS)

# Copy runtime dependencies
set(depsDir "${binaryDir}/install/dependencies")
file(GLOB dlDeps "${depsDir}/bin/*${dlExt}" "${depsDir}/lib/*${dlExt}")
file(INSTALL ${dlDeps}
    DESTINATION "${targetDir}/${dlDir}"
    USE_SOURCE_PERMISSIONS)

# Package the files
if((NOT DEFINED packager) OR (packager STREQUAL ""))
    if(WIN32)
        set(packager "zip")
    else()
        set(packager "tgz")
    endif()
endif()

if(packager STREQUAL "zip")
    executeProcess("zip" "-r" "${baseName}.zip" "${baseName}"
        WORKING_DIRECTORY "${releaseDir}")
elseif((packager STREQUAL "tar") OR (packager STREQUAL "tgz") OR (packager STREQUAL "tbz"))
    if(packager STREQUAL "tgz")
        set(tarCompression "-z")
        set(tarSuffix ".gz")
    elseif(packager STREQUAL "tbz")
        set(tarCompression "-j")
        set(tarSuffix ".bz2")
    else()
        set(tarCompression)
        set(tarSuffix)
    endif()
    executeProcess(
        "tar" "-c" "-v" ${tarCompression} "-f" "${baseName}.tar${tarSuffix}" "${baseName}"
        WORKING_DIRECTORY "${releaseDir}")
elseif(packager STREQUAL "none")
    message(STATUS "packager is 'none'; packaging skipped")
else()
    message(SEND_ERROR "'${packager}' is not a valid packager; packaging skipped")
endif()
