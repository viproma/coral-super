# This file defines a "super project" which downloads and builds all Coral
# dependencies before finally setting up Coral itself.
cmake_minimum_required(VERSION 3.3.0)
project("coral-super")

set(CORAL_MAIN_GIT_REPOSITORY "ssh://git@git.code.sintef.no/viproma/coral.git")

set(CORAL_GIT_REPOSITORY "${CORAL_MAIN_GIT_REPOSITORY}" CACHE STRING
    "The Coral repository URL. If you plan to develop Coral and submit pull requests, this should refer to your personal fork")
if(CORAL_GIT_REPOSITORY STREQUAL CORAL_MAIN_GIT_REPOSITORY)
    message(WARNING
        "CORAL_GIT_REPOSITORY currently points to the main Coral repository. If you plan to develop Coral and submit pull requests, you should change it so that it points to your personal fork.")
endif()

set(CORAL_GIT_TAG "master" CACHE STRING
    "The Git branch name, commit ID or tag to use when checking out Coral")

set(INSTALL_DIR "${CMAKE_BINARY_DIR}/install" CACHE PATH
    "The directory under which all external projects will be installed")
set(depsInstallPrefix "${INSTALL_DIR}/dependencies")
set(coralInstallPrefix "${INSTALL_DIR}/coral")
set(jdsbInstallPrefix "${INSTALL_DIR}/jdsb")

include(ExternalProject)


# ==============================================================================
# Boost
# ==============================================================================

if(MSVC)
    option(DOWNLOAD_BOOST
        "Download prebuilt Boost binaries for Microsoft Visual Studio (warning: big download)"
        OFF)
else()
    set(DOWNLOAD_BOOST OFF)
endif()

set(boostIncludeDirDocstring "The preferred Boost include directory (e.g. <prefix>/include)")
set(boostLibraryDirDocstring "The preferred Boost library directory (e.g. <prefix>/lib)")
if(DOWNLOAD_BOOST)
    set(boostDependency "boost")
    if(MSVC12)
        set(msvcVer "12.0")
        set(boostDownloadMD5 "b77904a3080b99b697d7eeb62582f73d")
    elseif(MSVC14)
        set(msvcVer "14.0")
        set(boostDownloadMD5 "44c64d563abb6934f152b4c9195d9532")
    else()
        message(FATAL_ERROR "Unsupported MSVC version for Boost download")
    endif()
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(wordSize "64")
    else()
        set(wordSize "32")
    endif()
    set(boostStem "boost_1_60_0")

    ExternalProject_Add(boost
        URL "http://marin-ikt.sintef.no/projects/viproma/downloads/${boostStem}-msvc-${msvcVer}-32-64.tar.gz"
        SOURCE_DIR "${depsInstallPrefix}/${boostStem}"
        BINARY_DIR "${depsInstallPrefix}/${boostStem}"
        INSTALL_DIR "${depsInstallPrefix}/${boostStem}"
        URL_MD5 "${boostDownloadMD5}"
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
    )
    ExternalProject_Get_Property(boost INSTALL_DIR)
    set(BOOST_INCLUDEDIR "${INSTALL_DIR}"
        CACHE PATH "${boostIncludeDirDocstring}" FORCE)
    set(BOOST_LIBRARYDIR "${INSTALL_DIR}/lib${wordSize}-msvc-${msvcVer}"
        CACHE PATH "${boostLibraryDirDocstring}" FORCE)
else()
    set(boostDependency)
    set(BOOST_INCLUDEDIR ""
        CACHE PATH "${boostIncludeDirDocstring}")
    set(BOOST_LIBRARYDIR ""
        CACHE PATH "${boostLibraryDirDocstring}")
endif()

if((NOT BOOST_INCLUDEDIR) OR (NOT BOOST_LIBRARYDIR))
    message("The variable(s) BOOST_INCLUDEDIR and/or BOOST_LIBRARYDIR were not defined. If they are, they will be passed on to the CMake scripts of subprojects that need them.")
endif()

unset(boostCMakeArgs)
if(BOOST_INCLUDEDIR)
    list(APPEND boostCMakeArgs "-DBOOST_INCLUDEDIR:PATH=${BOOST_INCLUDEDIR}")
else()
    message("The variable BOOST_INCLUDEDIR was not defined. If it is, it will be passed on to the CMake scripts of subprojects that depend on Boost.")
endif()
if(BOOST_LIBRARYDIR)
    list(APPEND boostCMakeArgs "-DBOOST_LIBRARYDIR:PATH=${BOOST_LIBRARYDIR}")
else()
    message("The variable BOOST_LIBRARYDIR was not defined. If it is, it will be passed on to the CMake scripts of subprojects that depend on Boost.")
endif()


# ==============================================================================
# Other dependencies
# ==============================================================================

ExternalProject_Add(zlib
    GIT_REPOSITORY "https://github.com/madler/zlib.git"
    GIT_TAG "v1.2.8"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX:PATH=${depsInstallPrefix}"
    INSTALL_DIR "${depsInstallPrefix}"
)

ExternalProject_Add(libzip
    DEPENDS "zlib"
    HG_REPOSITORY "http://hg.nih.at/libzip"
    HG_TAG "rel-1-1-2"
    PATCH_COMMAND "hg" "revert" "."
          COMMAND "hg" "import" "${CMAKE_SOURCE_DIR}/patches/libzip.patch"
            "--config" "patch.eol=auto" "--no-commit"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX:PATH=${depsInstallPrefix}"
    INSTALL_DIR "${depsInstallPrefix}"
)

ExternalProject_Add(fmilib
    SVN_REPOSITORY "https://svn.jmodelica.org/FMILibrary/tags/2.0.1"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${depsInstallPrefix}"
        "-DFMILIB_INSTALL_PREFIX:PATH=${depsInstallPrefix}"
        "-DFMILIB_BUILD_SHARED_LIB:BOOL=ON"
        "-DFMILIB_BUILD_STATIC_LIB:BOOL=OFF"
        "-DFMILIB_BUILD_TESTS:BOOL=OFF"
    INSTALL_DIR "${depsInstallPrefix}"
)

ExternalProject_Add(protobuf
    GIT_REPOSITORY "https://github.com/google/protobuf.git"
    GIT_TAG "v3.0.0-beta-2"
    PATCH_COMMAND "${CMAKE_COMMAND}" "-E" "copy"
        "${CMAKE_SOURCE_DIR}/patches/protobuf/CMakeLists.txt"
        "${CMAKE_BINARY_DIR}/protobuf-prefix/src/protobuf/"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${depsInstallPrefix}"
        "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
        "-Dprotobuf_MSVC_STATIC_RUNTIME=OFF"
    INSTALL_DIR "${depsInstallPrefix}"
)

ExternalProject_Add(zmq
    GIT_REPOSITORY "https://github.com/zeromq/zeromq4-1.git"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${depsInstallPrefix}"
        "-DWITH_LIBSODIUM:BOOL=OFF"
        "-DZMQ_BUILD_TESTS:BOOL=OFF"
    INSTALL_DIR "${depsInstallPrefix}"
)


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

ExternalProject_Add(dsb
    GIT_REPOSITORY "${CORAL_GIT_REPOSITORY}"
    GIT_TAG "${CORAL_GIT_TAG}"
    DEPENDS "libzip" "fmilib" "protobuf" "zmq" ${boostDependency}
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX:PATH=${coralInstallPrefix}"
        "-DCMAKE_PREFIX_PATH=${depsInstallPrefix}"
        "-DCORAL_BUILD_PRIVATE_API_DOCS:BOOL=ON"
        ${boostCMakeArgs}
        "-DPROTOBUF_LIBRARY=${depsInstallPrefix}/lib/${libprotobuf}"
        "-DPROTOBUF_LIBRARY_DEBUG=${depsInstallPrefix}/lib/${libprotobufd}"
    INSTALL_DIR "${coralInstallPrefix}"
)


option (BUILD_JDSB "Build JDSB too" OFF)

if (BUILD_JDSB)
    ExternalProject_Add(jdsb
        GIT_REPOSITORY "ssh://git@git.code.sintef.no/vista/jdsb.git"
        DEPENDS "dsb"
        CMAKE_ARGS
            "-DCMAKE_INSTALL_PREFIX:PATH=${jdsbInstallPrefix}"
            "-DCMAKE_PREFIX_PATH=${depsInstallPrefix};${coralInstallPrefix}"
            ${boostCMakeArgs}
            "-DPROTOBUF_LIBRARY=${depsInstallPrefix}/lib/${libprotobuf}"
            "-DPROTOBUF_LIBRARY_DEBUG=${depsInstallPrefix}/lib/${libprotobufd}"
        INSTALL_DIR "${jdsbInstallPrefix}"
        INSTALL_COMMAND "" # JDSB currently doesn't have an install step
    )
endif()
