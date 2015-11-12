function(configure_project name repo)
  #  cmake_parse_arguments(PKG "" "NAME;REPO" "" ${ARGN} )
  set(PKG_NAME ${name})
  set(PKG_REPO ${repo})
  option(WITH_${PKG_NAME} "Set ON to use ${PKG_NAME}" ON)
  string(TOLOWER ${PKG_NAME} PKG_NAME_)
  if(WITH_${PKG_NAME})
    find_package(${PKG_NAME})
    if(${PKG_NAME}_FOUNDXX)
      set(GDAL_USES_EXTERNAL_${PKG_NAME} TRUE CACHE INTERNAL "compiles ${PKG_NAME} with build"  )
    else()
      # external projext
      ExternalProject_Add(${PKG_NAME}
        GIT_REPOSITORY ${EP_URL}/${PKG_REPO}
        INSTALL_COMMAND "" # no install
        )

      #TODO: need a better way inside nextgis_extra/lib_z repo
      set (${PKG_NAME}_INCLUDE_DIRS ${ep_base}/Source/${PKG_NAME} ${ep_base}/Build/${PKG_NAME})
      
    endif()
    
    #TODO: need a better way inside nextgis_extra/lib_z repo
    if (MSVC)
      set(ZLIB_LIBRARIES
        DEBUG           "${ZLIB_BLD_DIR}/Debug/${CMAKE_STATIC_LIBRARY_PREFIX}zlibd${CMAKE_STATIC_LIBRARY_SUFFIX}"
        RELEASE         "${ZLIB_BLD_DIR}/Release/${CMAKE_STATIC_LIBRARY_PREFIX}zlib${CMAKE_STATIC_LIBRARY_SUFFIX}"
        )
    else()
      set(ZLIB_LIBRARIES
        "${ZLIB_BLD_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}z${CMAKE_STATIC_LIBRARY_SUFFIX}"
        )
    endif()

    
    include_directories(${${PKG_NAME}_INCLUDE_DIRS})
    

endif()

endfunction()
