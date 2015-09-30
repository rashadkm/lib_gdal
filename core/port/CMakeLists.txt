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

cmake_minimum_required (VERSION 2.8.10 FATAL_ERROR)

set(LIB_NAME "cpl")
project ("lib${LIB_NAME}")

include(configure)

include_directories(${GDAL_ROOT_BINARY_DIR}/port)

set(LIB_HHEADERS
    cpl_atomic_ops.h
    cpl_config_extras.h
    cpl_conv.h
    cpl_csv.h
    cpl_error.h
    cpl_hash_set.h
    cpl_http.h
    cplkeywordparser.h
    cpl_list.h
    cpl_minixml.h
    cpl_multiproc.h
    cpl_port.h
    cpl_progress.h
    cpl_quad_tree.h
    cpl_spawn.h
    cpl_string.h
    cpl_time.h
    cpl_virtualmem.h
    cpl_vsi.h
    cpl_vsi_virtual.h
    cpl_worker_thread_pool.h
    gdal_csv.h
)

set(LIB_CSOURCES
    cpl_atomic_ops.cpp
    cpl_base64.cpp
    cpl_conv.cpp
    cpl_csv.cpp
    cpl_error.cpp
    cpl_findfile.cpp
    cpl_getexecpath.cpp
    cplgetsymbol.cpp
    cpl_google_oauth2.cpp
    cpl_hash_set.cpp
    cpl_http.cpp
    cplkeywordparser.cpp
    cpl_list.cpp
    cpl_minixml.cpp
    cpl_multiproc.cpp
    cpl_path.cpp
    cpl_progress.cpp
    cpl_quad_tree.cpp
    cpl_recode.cpp
    cpl_recode_stub.cpp
    cpl_spawn.cpp
    cpl_string.cpp
    cplstring.cpp
    cplstringlist.cpp
    cpl_strtod.cpp
    cpl_time.cpp
    cpl_virtualmem.cpp
    cpl_vsil_abstract_archive.cpp
    cpl_vsil_buffered_reader.cpp
    cpl_vsil_cache.cpp
    cpl_vsil.cpp
#    cpl_vsil_simple.cpp
    cpl_vsil_sparsefile.cpp
    cpl_vsil_stdin.cpp
    cpl_vsil_stdout.cpp
    cpl_vsil_subfile.cpp
    cpl_vsil_tar.cpp
    cpl_vsi_mem.cpp
    cpl_vsisimple.cpp
    cpl_worker_thread_pool.cpp
    cpl_xml_validate.cpp
)

if(WIN32)
    set(LIB_CSOURCES ${LIB_CSOURCES} cpl_vsil_win32.cpp)
else(WIN32)
    set(LIB_CSOURCES ${LIB_CSOURCES} cpl_vsil_unix_stdio_64.cpp)
endif(WIN32)

#check odbc
option(GDAL_USE_ODBC "Set ON to use odbc" OFF)
if(GDAL_USE_ODBC)
    set(LIB_HHEADERS ${LIB_HHEADERS} cpl_odbc.h)
    set(LIB_CSOURCES ${LIB_CSOURCES} cpl_odbc.cpp)
endif(GDAL_USE_ODBC)

option(GDAL_USE_XMLREFORMAT "Set ON to use xmlreformat" OFF)
if(GDAL_USE_XMLREFORMAT)
    set(LIB_CSOURCES ${LIB_CSOURCES} xmlreformat.cpp)
endif(GDAL_USE_XMLREFORMAT)

option(GDAL_USE_ONLY_CRYPTODLL_ALG "Include cryptopp support" OFF)
if(GDAL_USE_ONLY_CRYPTODLL_ALG)
    #todo: check cryptopp func
    add_definitions(-DUSE_ONLY_CRYPTODLL_ALG)
endif(GDAL_USE_ONLY_CRYPTODLL_ALG)

if(HAVE_ICONV)
    set(LIB_CSOURCES ${LIB_CSOURCES}
        cpl_recode_iconv.cpp
    )
    include_directories(${ICONV_INCLUDE_DIR})
    add_definitions(-DHAVE_ICONV -DLIBICONV_PLUG)
endif()

#check zip and internal zip
option(GDAL_USE_LIBZ "Set ON to use libz" ON)
if(GDAL_USE_LIBZ)
    option(GDAL_USE_LIBZ_INTERNAL "Set ON to use internal libz" OFF)
    add_definitions(-DHAVE_LIBZ -DZIP_SUPPORT)
    set(LIB_HHEADERS ${LIB_HHEADERS}
        cpl_minizip_ioapi.h
        cpl_minizip_unzip.h
        cpl_minizip_zip.h
    )

    set(LIB_CSOURCES ${LIB_CSOURCES}
        cpl_vsil_gzip.cpp
        cpl_minizip_ioapi.cpp
        cpl_minizip_unzip.cpp
        cpl_minizip_zip.cpp
    )
    if(GDAL_USE_LIBZ_INTERNAL)    
        option(GDAL_USE_LIBZ_INTERNAL_SHARED "Set ON to use shared libz" ON)    
        set (ZLIB_SRC_DIR ${ep_base}/Source/zlib CACHE INTERNAL "zlib internal sources path")
        set (ZLIB_BLD_DIR ${ep_base}/Build/zlib CACHE INTERNAL "zlib internal build path")
        # external project
        ExternalProject_Add(zlib
            GIT_REPOSITORY ${EP_URL}/lib_z
            INSTALL_COMMAND "" # no install
        )        
        set (ZLIB_INCLUDE_DIRS ${ZLIB_SRC_DIR} ${ZLIB_BLD_DIR})        
        if (MSVC)
            set_libraries(ZLIB_LIBRARIES GDAL_USE_LIBZ_INTERNAL_SHARED ${ZLIB_BLD_DIR} "zlib" "zlibd") 
        else()
            set_libraries(ZLIB_LIBRARIES GDAL_USE_LIBZ_INTERNAL_SHARED ${ZLIB_BLD_DIR} "z" "z")         
        endif()
        
        set(ZLIB_FOUND ON)
    else()
        find_package(ZLIB REQUIRED)        
    endif()
    
    if(ZLIB_FOUND)
        include_directories(${ZLIB_INCLUDE_DIRS})
        add_definitions(-DHAVE_ZLIB_H -DHAVE_ZLIB)
        if(MSVC)
            add_definitions(-DZLIB_DLL)
        endif()
    endif()
else()
    message(WARNING "No zlib support")
endif()

#check curl
option(GDAL_USE_CURL "Set ON to use libcurl" ON)
if(GDAL_USE_CURL)
    option(GDAL_USE_CURL_INTERNAL "Set ON to use internal libcurl" OFF)
    add_definitions(-DHAVE_CURL)
    set(LIB_HHEADERS ${LIB_HHEADERS}
        cpl_vsil_curl_priv.h
    )

    set(LIB_CSOURCES ${LIB_CSOURCES}
        cpl_vsil_curl.cpp
        cpl_vsil_curl_streaming.cpp
    )

    if(GDAL_USE_CURL_INTERNAL)
        option(GDAL_USE_CURL_INTERNAL_SHARED "Set ON to use shared curl" ON)   
        option(GDAL_USE_OPENSSL_INTERNAL "Set ON to use openssl internal" ON)       
        set (CURL_SRC_DIR ${ep_base}/Source/curl CACHE INTERNAL "curl internal sources path")
        set (CURL_BLD_DIR ${ep_base}/Build/curl CACHE INTERNAL "curl internal build path")
        # external project
        
        ExternalProject_Add(curl
            DEPENDS zlib
            GIT_REPOSITORY ${EP_URL}/lib_curl
            CMAKE_ARGS
            -DBUILD_CURL_TESTS=OFF
            -DCURL_DISABLE_FTP=ON
            -DCURL_DISABLE_LDAP=ON
            -DCURL_DISABLE_TELNET=ON
            -DCURL_DISABLE_DICT=ON
            -DCURL_DISABLE_FILE=ON
            -DCURL_DISABLE_TFTP=ON
            -DCURL_DISABLE_LDAPS=ON
            -DCURL_DISABLE_RTSP=ON
            -DCURL_DISABLE_PROXY=ON
            -DCURL_DISABLE_POP3=ON
            -DCURL_DISABLE_IMAP=ON
            -DCURL_DISABLE_SMTP=ON
            -DCURL_DISABLE_GOPHER=ON
            -DCURL_DISABLE_CRYPTO_AUTH=OFF
            -DENABLE_IPV6=OFF
            -DENABLE_MANUAL=OFF
            -DCMAKE_USE_OPENSSL=ON
            -DCMAKE_USE_LIBSSH2=OFF
            -DCMAKE_USE_OPENSSL_INTERNAL=${GDAL_USE_OPENSSL_INTERNAL}
            -DCURL_ZLIB_INTERNAL=${GDAL_USE_LIBZ_INTERNAL}
            INSTALL_COMMAND ""
        )
        
        set (CURL_INCLUDE_DIRS ${CURL_SRC_DIR} ${CURL_BLD_DIR})        
        if (MSVC)
            set_libraries(CURL_LIBRARIES GDAL_USE_CURL_INTERNAL_SHARED ${CURL_BLD_DIR} "curl" "curld") 
        else()
            set_libraries(CURL_LIBRARIES GDAL_USE_CURL_INTERNAL_SHARED ${CURL_BLD_DIR} "curl" "curl")         
        endif()
        
        set(CURL_FOUND ON)
    else()
        find_package(CURL REQUIRED)        
    endif()
    
    if(CURL_FOUND)
        include_directories(${CURL_INCLUDE_DIRS})
    endif()
else()
     message(WARNING "No libcurl support")    
endif()

add_library(${LIB_NAME} OBJECT ${LIB_HHEADERS} ${LIB_CSOURCES})

if(HAVE_ICONV)
    set(GDAL_TARGET_LINK_LIB ${GDAL_TARGET_LINK_LIB} ${ICONV_LIBRARIES})
endif()

if(GDAL_USE_LIBZ)
    if(GDAL_USE_LIBZ_INTERNAL)        
        add_dependencies(${LIB_NAME} zlib)
    endif()
    
    set(GDAL_TARGET_LINK_LIB ${GDAL_TARGET_LINK_LIB} ${ZLIB_LIBRARIES})
endif()

if(GDAL_USE_CURL)
    if(GDAL_USE_CURL_INTERNAL)        
        add_dependencies(${LIB_NAME} curl)
    endif() 
        
    set(GDAL_TARGET_LINK_LIB ${GDAL_TARGET_LINK_LIB} ${CURL_LIBRARIES})   
endif()

# build target
set(GDAL_TARGET_OBJECTS ${GDAL_TARGET_OBJECTS} $<TARGET_OBJECTS:${LIB_NAME}> PARENT_SCOPE)
set(GDAL_TARGET_LINK_LIB ${GDAL_TARGET_LINK_LIB} PARENT_SCOPE)

# install headers
set(GDAL_INSTALL_HEADERS ${GDAL_INSTALL_HEADERS} ${LIB_HHEADERS} PARENT_SCOPE)