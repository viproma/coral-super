# This is a "dependency" whose only purpose is to install the
# C/C++ system runtime files.
cmake_minimum_required(VERSION 3.0.0)
project("coral-super-crt-install")

include(InstallRequiredSystemLibraries)
if(WIN32)
    set(installDir "bin")
else()
    set(installDir "lib")
endif()
install(PROGRAMS ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} DESTINATION "${installDir}")
