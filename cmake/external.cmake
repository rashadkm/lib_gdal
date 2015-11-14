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
      
      set(${PKG_NAME}_INCLUDE_DIRS ${ep_base}/Source/${PKG_NAME} ${ep_base}/Build/${PKG_NAME})
    endif()

    add_library(${PKG_NAME}_IMP SHARED IMPORTED)
    set_property(TARGET ${PKG_NAME}_IMP PROPERTY IMPORTED_LOCATION ${ep_base}/Build/${PKG_NAME}/libz.so)
    
#    include_directories(${${PKG_NAME}_INCLUDE_DIRS})   

endif()

endfunction()
