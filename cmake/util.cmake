################################################################################
# Project:  CMake4GDAL
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, polimax@mail.ru
################################################################################
# Copyright (C) 2015, NextGIS <info@nextgis.com>
# Copyright (C) 2012,2013,2014 Dmitry Baryshnikov
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################


function(check_version major minor rev)

# parse the version number from gdal_version.h and include in
# major, minor and rev parameters

file(READ ${CMAKE_CURRENT_SOURCE_DIR}/core/gcore/gdal_version.h GDAL_VERSION_H_CONTENTS)

string(REGEX MATCH "GDAL_VERSION_MAJOR[ \t]+([0-9]+)"
  GDAL_MAJOR_VERSION ${GDAL_VERSION_H_CONTENTS})
string (REGEX MATCH "([0-9]+)"
  GDAL_MAJOR_VERSION ${GDAL_MAJOR_VERSION})
string(REGEX MATCH "GDAL_VERSION_MINOR[ \t]+([0-9]+)"
  GDAL_MINOR_VERSION ${GDAL_VERSION_H_CONTENTS})
string (REGEX MATCH "([0-9]+)"
  GDAL_MINOR_VERSION ${GDAL_MINOR_VERSION})
string(REGEX MATCH "GDAL_VERSION_REV[ \t]+([0-9]+)"
  GDAL_REV_VERSION ${GDAL_VERSION_H_CONTENTS})
string (REGEX MATCH "([0-9]+)"
  GDAL_REV_VERSION ${GDAL_REV_VERSION})

set(${major} ${GDAL_MAJOR_VERSION} PARENT_SCOPE)
set(${minor} ${GDAL_MINOR_VERSION} PARENT_SCOPE)
set(${rev} ${GDAL_REV_VERSION} PARENT_SCOPE)

endfunction(check_version)

# search python module
function(find_python_module module)
    string(TOUPPER ${module} module_upper)
    if(ARGC GREATER 1 AND ARGV1 STREQUAL "REQUIRED")
        set(${module}_FIND_REQUIRED TRUE)
    else()
        if (ARGV1 STREQUAL "QUIET")
            set(PY_${module}_FIND_QUIETLY TRUE)
        endif()
    endif()

    if(NOT PY_${module_upper})
        # A module's location is usually a directory, but for binary modules
        # it's a .so file.
        execute_process(COMMAND "${PYTHON_EXECUTABLE}" "-c"
            "import re, ${module}; print(re.compile('/__init__.py.*').sub('',${module}.__file__))"
            RESULT_VARIABLE _${module}_status
            OUTPUT_VARIABLE _${module}_location
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(NOT _${module}_status)
            set(PY_${module_upper} ${_${module}_location} CACHE STRING
                "Location of Python module ${module}")
        endif(NOT _${module}_status)
    endif(NOT PY_${module_upper})
    find_package_handle_standard_args(PY_${module} DEFAULT_MSG PY_${module_upper})
endfunction(find_python_module)



#need a location outside build ?
set(DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/third-party/downloads")

include(CMakeParseArguments)

set(ZLIB_URL  "http://sourceforge.net/projects/libpng/files/zlib/1.2.8/zlib-1.2.8.tar.gz/download")
set(ZLIB_MD5  "44d667c142d7cda120332623eab69f40")
#could there be a default?
set(ZLIB_DOWNLOAD_NAME "zlib-1.2.8.tar.gz")

set(CURL_URL  "http://curl.haxx.se/download/curl-7.40.0.tar.gz")
set(CURL_MD5  "58943642ea0ed050ab0431ea1caf3a6f")
set(CURL_DOWNLOAD_NAME "curl-7.40.0.tar.gz")

#erg.. no cmake build
set(OPENSSL_URL  "https://github.com/openssl/openssl/archive/OpenSSL_1_0_1e.zip")
set(OPENSSL_MD5  "de0f06b07dad7ec8b220336530be1feb")
set(OPENSSL_DOWNLOAD_NAME "OpenSSL_1_0_1e.zip")

#need a better way. discuss with dimitry
set(ZLIB_INSTALL_DIR "${CMAKE_BINARY_DIR}/third-party/Install/ZLIB")
set(CURL_INSTALL_DIR "${CMAKE_BINARY_DIR}/third-party/Install/CURL")

set(OPENSSL_INSTALL_DIR "${CMAKE_BINARY_DIR}/third-party/Install/OPENSSL")

function(configure_external_project)
  cmake_parse_arguments(PKG "" "NAME" "DEPENDS" ${ARGN} )
  option(WITH_${PKG_NAME} "Set ON to use ${PKG_NAME}" ON)

  if(WITH_${PKG_NAME})
    foreach(DEPEND ${PKG_DEPENDS})
      if(NOT TARGET ${DEPEND})
        configure_external_project(NAME ${DEPEND})
        set(${PKG_NAME}_CMAKE_CONFIG "-D${DEPEND}_INCLUDE_DIRS=${GDAL_${DEPEND}_INCLUDE_DIRS} -D${DEPEND}_LIBRARIES=${GDAL_${DEPEND}_LIBRARIES}")
      endif()
    endforeach()

    find_package(${PKG_NAME})

    if(${PKG_NAME}_FOUND)
      set(GDAL_${PKG_NAME}_INCLUDE_DIRS ${${PKG_NAME}_INCLUDE_DIRS} "internal cmake var to hold ${PKG_NAME}'s headers" INTERNAL)
      set(GDAL_${PKG_NAME}_LIBRARIES ${${PKG_NAME}_PKGRARIES} "internal cmake var to hold ${PKG_NAME}'s lib" INTERNAL)
    else()

      FILE(READ "${CMAKE_SOURCE_DIR}/cmake/cache/${PKG_NAME}-cache.cmake" ${PKG_NAME}_CACHE_ARGS_LIST)
      STRING(REGEX REPLACE ";" "\\\\;" ${PKG_NAME}_CACHE_ARGS_LIST "${${PKG_NAME}_CACHE_ARGS_LIST}")
      STRING(REGEX REPLACE "\n" ";" ${PKG_NAME}_CACHE_ARGS_LIST "${${PKG_NAME}_CACHE_ARGS_LIST}")

      list(APPEND ${PKG_NAME}_CACHE_ARGS_LIST -DCMAKE_INSTALL_PREFIX:PATH=${${PKG_NAME}_INSTALL_DIR})
      list(APPEND ${PKG_NAME}_CACHE_ARGS_LIST ${${PKG_NAME}_CMAKE_CONFIG})
      message(WARNING ${${PKG_NAME}_CACHE_ARGS_LIST})

      #add externalproject
        ExternalProject_Add(${PKG_NAME}
          DEPENDS ${PKG_DEPENDS}
          URL ${${PKG_NAME}_URL}
          URL_MD5 ${${PKG_NAME}_MD5}
          DOWNLOAD_NAME ${${PKG_NAME}_DOWNLOAD_NAME}
          DOWNLOAD_DIR ${DOWNLOAD_LOCATION}
          CMAKE_CACHE_ARGS ${${PKG_NAME}_CACHE_ARGS_LIST}
          )

        set(GDAL_${PKG_NAME}_INCLUDE_DIRS ${${PKG_NAME}_INSTALL_DIR}/include "internal cmake var to hold ${PKG_NAME}'s headers" INTERNAL)
        set(GDAL_${PKG_NAME}_LIBRARIES ${${PKG_NAME}_INSTALL_DIR}/lib/libz.so "internal cmake var to hold ${PKG_NAME}'s lib" INTERNAL)
      endif()

      list(APPEND GDAL_TARGET_LINK_LIB ${GDAL_${PKG_NAME}_LIBRARIES})

  endif()

endfunction()
