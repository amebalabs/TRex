# ===================================================================================
#  The Tesseract CMake configuration file
#
#             ** File generated automatically, do not modify **
#
#  Usage from an external project:
#    In your CMakeLists.txt, add these lines:
#
#    find_package(Tesseract REQUIRED)
#    target_link_libraries(MY_TARGET_NAME Tesseract::libtesseract)
#
#    This file will define the following variables:
#      - Tesseract_LIBRARIES             : The list of all imported targets.
#      - Tesseract_INCLUDE_DIRS          : The Tesseract include directories.
#      - Tesseract_LIBRARY_DIRS          : The Tesseract library directories.
#      - Tesseract_VERSION               : The version of this Tesseract build: "5.3.3"
#      - Tesseract_VERSION_MAJOR         : Major version part of Tesseract_VERSION: "5"
#      - Tesseract_VERSION_MINOR         : Minor version part of Tesseract_VERSION: "3"
#      - Tesseract_VERSION_PATCH         : Patch version part of Tesseract_VERSION: "3"
#
# ===================================================================================

include(CMakeFindDependencyMacro)
find_dependency(Leptonica)

include(${CMAKE_CURRENT_LIST_DIR}/TesseractTargets.cmake)


####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was TesseractConfig.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################

SET(Tesseract_VERSION           5.3.3)
SET(Tesseract_VERSION_MAJOR     5)
SET(Tesseract_VERSION_MINOR     3)
SET(Tesseract_VERSION_PATCH     3)

set_and_check(Tesseract_INCLUDE_DIRS "${PACKAGE_PREFIX_DIR}/include")
set_and_check(Tesseract_LIBRARY_DIRS "${PACKAGE_PREFIX_DIR}/lib")
set(Tesseract_LIBRARIES tesseract$<$<BOOL:>:53$<$<CONFIG:DEBUG>:d>>)

check_required_components(Tesseract)
