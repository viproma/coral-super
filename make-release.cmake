# This script creates a release bundle in the form of a ZIP file.
#
# USAGE
#
#   cmake -Dvar1=value1 -Dvar2=value2 -P make-release.cmake
#
# Note that the -P switch that specifies the script file MUST come after the
# -D switches that define variables.
#
# In its final step, creating the zip file, the script requires that the
# 'zip' program by Info-ZIP is in the PATH environment variable.  On Linux,
# this is often the case already, and if not, it can be easily installed
# through most distributions' package management systems.  On Windows, one
# can use Cygwin or download the program from http://www.info-zip.org.
# Alternatively, this step can be disabled by setting the 'createZip'
# variable to FALSE.
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
#   createZip           Whether to create a ZIP file.  This is ON by default.
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
    set(dlExt ".dll")
    set(exeExt ".exe")
else()
    set(dlExt ".so")
    set(exeExt "")
endif()

# Copy Coral files
file(INSTALL "${binaryDir}/install/coral/" DESTINATION "${targetDir}")

# Copy runtime dependencies
set(depsDir "${binaryDir}/install/dependencies")
file(GLOB dlDeps "${depsDir}/bin/*${dlExt}" "${depsDir}/lib/*${dlExt}")
file(INSTALL ${dlDeps} DESTINATION "${targetDir}/bin")

# Create the ZIP file
if(createZip OR NOT DEFINED createZip)
    executeProcess("zip" "-r" "${baseName}.zip" "${baseName}"
        WORKING_DIRECTORY "${releaseDir}")
else()
    message(STATUS "createZip is OFF; ZIP file creation skipped.")
endif()
