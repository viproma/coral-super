# This file defines a "super project" which downloads and builds all Coral
# dependencies before finally setting up Coral itself.
cmake_minimum_required(VERSION 3.0.0)
project("coral-super")

set(CORAL_MAIN_GIT_REPOSITORY "https://github.com/viproma/coral.git")
set(JCORAL_MAIN_GIT_REPOSITORY "https://github.com/viproma/jcoral.git")

set(CORAL_GIT_REPOSITORY "${CORAL_MAIN_GIT_REPOSITORY}" CACHE STRING
    "The Coral repository URL. If you plan to develop Coral and submit pull requests, this should refer to your personal fork")
if(CORAL_GIT_REPOSITORY STREQUAL CORAL_MAIN_GIT_REPOSITORY)
    message(WARNING
        "CORAL_GIT_REPOSITORY currently points to the main Coral repository. If you plan to develop Coral and submit pull requests, you should change it so that it points to your personal fork.")
endif()
set(CORAL_GIT_TAG "master" CACHE STRING
    "The Git branch name, commit ID or tag to use when checking out Coral")
set(CORAL_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install/coral" CACHE PATH
    "Where to install Coral")

if(BUILD_JCORAL)
    set(JCORAL_GIT_REPOSITORY "${JCORAL_MAIN_GIT_REPOSITORY}" CACHE STRING
        "The JCoral repository URL. If you plan to develop JCoral and submit pull requests, this should refer to your personal fork")
    if(JCORAL_GIT_REPOSITORY STREQUAL JCORAL_MAIN_GIT_REPOSITORY)
        message(WARNING
            "JCORAL_GIT_REPOSITORY currently points to the main JCoral repository. If you plan to develop JCoral and submit pull requests, you should change it so that it points to your personal fork.")
    endif()
    set(JCORAL_GIT_TAG "master" CACHE STRING
        "The Git branch name, commit ID or tag to use when checking out JCoral")
    set(JCORAL_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install/jcoral" CACHE PATH
        "Where to install JCoral")
endif()

set(DEPENDENCY_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install/dependencies" CACHE PATH
    "Where to install Coral dependencies")
option(INSTALL_DEBUG_RUNTIME_LIBRARIES
    "Whether to install the debug versions of system runtime libraries along with other dependencies. (Currently only applicable to the MSVC toolchain.)"
    OFF)

set(BOOST_ROOT "" CACHE PATH
    "Preferred Boost installation prefix")
set(BOOST_INCLUDEDIR "" CACHE PATH
    "Preferred Boost include directory (e.g. <prefix>/include)")
set(BOOST_LIBRARYDIR "" CACHE PATH
    "Preferred Boost library directory (e.g. <prefix>/lib)")

option(LIBZIP_USE_LIB_PREFIX_ON_WIN32
    "Whether to add a 'lib' prefix to the libzip library files on Windows. This is a workaround for a name conflict with a DLL bundled with Oracle's JVM, and should only be relevant if Coral is used through the JNI (as in JCoral). Since this script builds JCoral too, the workaround is enabled by default."
    ON)

set(forwardedVariables
    BOOST_INCLUDEDIR
    BOOST_LIBRARYDIR
    BOOST_ROOT
    CORAL_BUILD_PRIVATE_API_DOCS
    CORAL_BUILD_TESTS
    CORAL_ENABLE_DEBUG_LOGGING
    CORAL_ENABLE_TRACE_LOGGING
)
unset(forwardedVariablesArgs)
foreach(fv IN LISTS forwardedVariables)
    if(DEFINED ${fv})
        list(APPEND forwardedVariablesArgs "-D${fv}=${${fv}}")
    endif()
endforeach()


# ==============================================================================
# Dependencies
# ==============================================================================

include(ExternalProject)

ExternalProject_Add(zlib
    GIT_REPOSITORY "https://github.com/madler/zlib.git"
    GIT_TAG "v1.2.8"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
    INSTALL_DIR "${DEPENDENCY_INSTALL_PREFIX}"
)

# libzip must be built using autotools on Linux
if(WIN32)
    set(libzipSteps
        CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
                   "-DUSE_LIB_PREFIX_ON_WIN32=${LIBZIP_USE_LIB_PREFIX_ON_WIN32}"
    )
else()
    set(libzipSteps
        BINARY_DIR "${CMAKE_BINARY_DIR}/libzip-prefix/src/libzip"
        CONFIGURE_COMMAND "libtoolize"
                  COMMAND "autoheader"
                  COMMAND "aclocal"
                  COMMAND "autoconf"
                  COMMAND "automake" "--add-missing"
                  COMMAND "./configure" "--prefix=${DEPENDENCY_INSTALL_PREFIX}"
    )
endif()

ExternalProject_Add(libzip
    DEPENDS "zlib"
    GIT_REPOSITORY "https://github.com/nih-at/libzip.git"
    GIT_TAG "rel-1-1-3"
    PATCH_COMMAND "git" "apply" "${CMAKE_SOURCE_DIR}/patches/libzip/define-snprintf.patch"
                                "${CMAKE_SOURCE_DIR}/patches/libzip/dll-prefix-workaround.patch"
                                "${CMAKE_SOURCE_DIR}/patches/libzip/fix-manfmt.patch"
    ${libzipSteps}
    INSTALL_DIR "${DEPENDENCY_INSTALL_PREFIX}"
)

ExternalProject_Add(fmilib
    SVN_REPOSITORY "https://svn.jmodelica.org/FMILibrary/tags/2.0.3"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
        "-DFMILIB_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
        "-DFMILIB_BUILD_SHARED_LIB:BOOL=ON"
        "-DFMILIB_BUILD_STATIC_LIB:BOOL=OFF"
        "-DFMILIB_BUILD_TESTS:BOOL=OFF"
    INSTALL_DIR "${DEPENDENCY_INSTALL_PREFIX}"
)

ExternalProject_Add(protobuf
    GIT_REPOSITORY "https://github.com/google/protobuf.git"
    GIT_TAG "v3.0.0-beta-2"
    PATCH_COMMAND "${CMAKE_COMMAND}" "-E" "copy"
        "${CMAKE_SOURCE_DIR}/patches/protobuf/CMakeLists.txt"
        "${CMAKE_BINARY_DIR}/protobuf-prefix/src/protobuf/"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
        "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
        "-Dprotobuf_MSVC_STATIC_RUNTIME=OFF"
    INSTALL_DIR "${DEPENDENCY_INSTALL_PREFIX}"
)

ExternalProject_Add(zmq
    GIT_REPOSITORY "https://github.com/zeromq/zeromq4-1.git"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
        "-DWITH_LIBSODIUM:BOOL=OFF"
        "-DZMQ_BUILD_TESTS:BOOL=OFF"
    INSTALL_DIR "${DEPENDENCY_INSTALL_PREFIX}"
)

if(MSVC)
    ExternalProject_Add("coral-super-crt-install"
        URL "${CMAKE_SOURCE_DIR}/crt-install"
        CMAKE_ARGS
            "-DCMAKE_INSTALL_PREFIX:PATH=${DEPENDENCY_INSTALL_PREFIX}"
            "-DCMAKE_INSTALL_DEBUG_LIBRARIES=${INSTALL_DEBUG_RUNTIME_LIBRARIES}"
        INSTALL_DIR "${DEPENDENCY_INSTALL_PREFIX}"
    )
endif()


# ==============================================================================
# Coral
# ==============================================================================

if (WIN32)
    set(libprotobuf "libprotobuf.lib")
    set(libprotobufd "libprotobufd.lib")
else()
    set(libprotobuf "libprotobuf.a")
    set(libprotobufd "libprotobufd.a")
endif()

ExternalProject_Add(coral
    GIT_REPOSITORY "${CORAL_GIT_REPOSITORY}"
    GIT_TAG "${CORAL_GIT_TAG}"
    DEPENDS "libzip" "fmilib" "protobuf" "zmq"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${CORAL_INSTALL_PREFIX}"
        "-DCMAKE_PREFIX_PATH=${DEPENDENCY_INSTALL_PREFIX}"
        "-DCORAL_BUILD_PRIVATE_API_DOCS:BOOL=ON"
        ${forwardedVariablesArgs}
        "-DPROTOBUF_LIBRARY=${DEPENDENCY_INSTALL_PREFIX}/lib/${libprotobuf}"
        "-DPROTOBUF_LIBRARY_DEBUG=${DEPENDENCY_INSTALL_PREFIX}/lib/${libprotobufd}"
    INSTALL_DIR "${CORAL_INSTALL_PREFIX}"
)


# ==============================================================================
# JCoral
# ==============================================================================

if(BUILD_JCORAL)
    ExternalProject_Add(jcoral
        LIST_SEPARATOR "^"
        GIT_REPOSITORY "${JCORAL_GIT_REPOSITORY}"
        GIT_TAG "${JCORAL_GIT_TAG}"
        DEPENDS "coral"
        CMAKE_ARGS
            "-DCMAKE_INSTALL_PREFIX:PATH=${JCORAL_INSTALL_PREFIX}"
            "-DCMAKE_PREFIX_PATH=${CORAL_INSTALL_PREFIX}^${DEPENDENCY_INSTALL_PREFIX}"
            ${forwardedVariablesArgs}
            "-DPROTOBUF_LIBRARY=${DEPENDENCY_INSTALL_PREFIX}/lib/${libprotobuf}"
            "-DPROTOBUF_LIBRARY_DEBUG=${DEPENDENCY_INSTALL_PREFIX}/lib/${libprotobufd}"
        INSTALL_DIR "${JCORAL_INSTALL_PREFIX}"
    )
endif()
