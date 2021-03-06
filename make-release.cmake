cmake_minimum_required(VERSION 3.0.0)
#
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
#   jCoralReleaseName   A name for the JCoral release, typically a version
#                       number or commit hash.  If this is not specified,
#                       JCoral will not be built.
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
# The following variables will be automatically forwarded to CMake during the
# generation step if they are defined.  See README.md and Coral's own
# CMakeLists.txt for more information.

set(forwardedVariables
    BOOST_INCLUDEDIR
    BOOST_LIBRARYDIR
    BOOST_ROOT
    CORAL_BUILD_PRIVATE_API_DOCS
    CORAL_BUILD_TESTS
    CORAL_ENABLE_DEBUG_LOGGING
    CORAL_ENABLE_TRACE_LOGGING
    CORAL_GIT_REPOSITORY
    CORAL_GIT_TAG
    INSTALL_DEBUG_RUNTIME_LIBRARIES
    JCORAL_GIT_REPOSITORY
    JCORAL_GIT_TAG
)

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

# Creates an archive file.
function(package format baseName workingDir fileToAdd)
    if(format STREQUAL "zip")
        executeProcess("zip" "-r" "${baseName}.zip" "${fileToAdd}"
            WORKING_DIRECTORY "${workingDir}")
    elseif((format STREQUAL "tar") OR (format STREQUAL "tgz") OR (format STREQUAL "tbz"))
        if(format STREQUAL "tgz")
            set(tarCompression "-z")
            set(tarSuffix ".gz")
        elseif(format STREQUAL "tbz")
            set(tarCompression "-j")
            set(tarSuffix ".bz2")
        else()
            set(tarCompression)
            set(tarSuffix)
        endif()
        executeProcess(
            "tar" "-c" "-v" ${tarCompression} "-f" "${baseName}.tar${tarSuffix}" "${fileToAdd}"
            WORKING_DIRECTORY "${workingDir}")
    elseif(format STREQUAL "none")
        message(STATUS "package format is 'none'; packaging skipped")
    else()
        message(SEND_ERROR "'${format}' is not a valid package format; packaging skipped")
    endif()
endfunction()
# ------------------------------------------------------------------------------

set(packageName "coral")
set(releaseDir "releases")

if((NOT DEFINED releaseName) OR (releaseName STREQUAL ""))
    message(FATAL_ERROR "'releaseName' variable not defined")
endif()
set(baseName "${packageName}_${releaseName}")

if(jCoralReleaseName)
    set(buildJCoral TRUE)
    set(jCoralBaseName "jcoral_${jCoralReleaseName}")
endif()

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
            "-DBUILD_JCORAL=${buildJCoral}"
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
set(jCoralTargetDir "${releaseDir}/${jCoralBaseName}")
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
if(buildJCoral)
    file(INSTALL "${binaryDir}/install/jcoral/"
        DESTINATION "${jCoralTargetDir}"
        USE_SOURCE_PERMISSIONS)
endif()


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
package("${packager}" "${baseName}" "${releaseDir}" "${baseName}")
if(buildJCoral)
    package("${packager}" "${jCoralBaseName}" "${releaseDir}" "${jCoralBaseName}")
endif()
