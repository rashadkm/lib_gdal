function(configure_project name repo)
  #  cmake_parse_arguments(PKG "" "NAME;REPO" "" ${ARGN} )
  set(PKG_NAME ${name})
  set(PKG_REPO ${repo})
  option(WITH_${PKG_NAME} "Set ON to use ${PKG_NAME}" ON)
  string(TOLOWER ${PKG_NAME} PKG_NAME_)
  if(WITH_${PKG_NAME})
#    find_package(${PKG_NAME})
    if(${PKG_NAME}_FOUND)
      set(GDAL_USES_EXTERNAL_${PKG_NAME} TRUE CACHE INTERNAL "compiles ${PKG_NAME} with build"  )
    else()

      set(EP_URL "https://github.com/rashadkm/")
     
      ExternalProject_Add(${PKG_NAME}
        GIT_REPOSITORY ${EP_URL}/${PKG_REPO}
        DOWNLOAD_COMMAND ""
        CONFIGURE_COMMAND ""
        INSTALL_COMMAND
        )

      set(${PKG_NAME}_INSTALL_DIR ${CMAKE_BINARY_DIR}/third-party/Install/${PKG_NAME})
      
      if(NOT EXISTS "${CMAKE_BINARY_DIR}/third-party/Stamp/${PKG_NAME}/${PKG_NAME}-download")
        execute_process(COMMAND git clone ${EP_URL}/${PKG_REPO} ${PKG_NAME}
          WORKING_DIRECTORY  ${CMAKE_BINARY_DIR}/third-party/Source)
        
        execute_process(COMMAND ${CMAKE_COMMAND}  -E touch "${PKG_NAME}-download"
          WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/third-party/Stamp/${PKG_NAME} )  
      endif()
      
      execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_BINARY_DIR}/third-party/Source/${PKG_NAME}
        "-DCMAKE_INSTALL_PREFIX=${${PKG_NAME}_INSTALL_DIR}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/third-party/Build/${PKG_NAME} )
          
      include(${ep_base}/Build/${PKG_NAME}/${PKG_NAME}Targets.cmake)

      ##TODO: need to get this name from ${PKG_NAME}Targets.cmake or better ${PKG_NAME}Config.cmake
      set(ZLIB_LIBNAME ${PKG_NAME_})
    
      get_target_property(${PKG_NAME}_LIBLOC ${${PKG_NAME}_LIBNAME} IMPORTED_LOCATION_NOCONFIG)
      set(GDAL_TARGET_LINK_LIB ${GDAL_TARGET_LINK_LIB} ${${PKG_NAME}_LIBLOC} PARENT_SCOPE)

      #ExternalProject_Get_Property(${PKG_NAME} install_dir)
      include_directories(${${PKG_NAME}_INSTALL_DIR}/include)

      
      
    endif()

endif()

endfunction()

macro(update_link_libraries targ dep)
  string(TOUPPER ${targ} targ_)
  
  if(WITH_${dep}) #do we really need to check this ?
    
    if(NOT GDAL_USES_EXTERNAL_${dep})
      add_dependencies(${targ} ${dep})
    endif()
#    get_target_property(${dep}_imported_libs ${dep}_IMP IMPORTED_LOCATION)
#    list(APPEND ${targ_}_LINK_LIBRARIES zlib)
  endif()

  #include_directories(${${dep}_INCLUDE_DIRS})

  #get_target_property(VAR ${dep}_IMP IMPORTED_LOCATION)
  #message(FATAL_ERROR "VAR=${VAR}")
  
endmacro()


