#[=======================================================================[.rst
FindCarlaUtils
--------------

FindModule for carla-utils and associated libraries

Result Variables
^^^^^^^^^^^^^^^^

This module sets the following variables:

``CarlaUtils_FOUND``
  True, if all required components and the core library were found.

Cache variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``CarlaUtils_LIBRARIES``
  Path to the library component of carla-utils
``CarlaUtils_INCLUDE_DIRS``
  Directories used by carla-utils.

#]=======================================================================]

include(FindPackageHandleStandardArgs)

# if pkg-config file is found, let it handle everything for us
find_package(PkgConfig) # QUIET
if(PKG_CONFIG_FOUND)
  pkg_check_modules(PC_CarlaUtils IMPORTED_TARGET carla-utils) # QUIET

  if(${PC_CarlaUtils_FOUND})
    message("DEBUG: using carla-utils pkg-config")
    add_library(carla::utils ALIAS PkgConfig::PC_CarlaUtils)
    set(CarlaUtils_FOUND TRUE)
    mark_as_advanced(CarlaUtils_FOUND)
    return()
  else()
    message("DEBUG: NOT using carla-utils pkg-config")
  endif()
else()
  message("DEBUG: NOT using pkg-config")
endif()

# if using macOS, let frameworks handle everything for us
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  find_library(CarlaUtils_LIBRARY NAMES carla-utils)

  # if(${CarlaUtils_LIBRARY})
    message("DEBUG: using carla-utils.framework - ${CarlaUtils_LIBRARY}")
    add_library(carla::utils UNKNOWN IMPORTED GLOBAL)
    set_target_properties(carla::utils PROPERTIES IMPORTED_LOCATION "${CarlaUtils_LIBRARY}")
    set_target_properties(carla::utils PROPERTIES FRAMEWORK TRUE)
    set_target_properties(carla::utils PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${CarlaUtils_LIBRARY}/Headers")
    set(CarlaUtils_FOUND TRUE)
    mark_as_advanced(CarlaUtils_FOUND)
    return()
  # else()
    # message("DEBUG: NOT using carla-utils.framework - ${CarlaUtils_LIBRARY}")
  # endif()
endif()

find_path(
  CarlaUtils_INCLUDE_DIR
  NAMES utils/CarlaBridgeUtils.hpp
  PATHS /usr/include /usr/local/include
  PATH_SUFFIXES carla
  DOC "carla include directory")

find_library(
  CarlaUtils_LIBRARY
  NAMES carla_utils libcarla_utils
  PATHS /usr/lib /usr/local/lib
  PATH_SUFFIXES carla)

find_program(
  CarlaUtils_BRIDGE_LV2_GTK2
  NAMES carla-bridge-lv2-gtk2
  HINTS ${CarlaUtils_LIBRARY}
  PATHS /usr/lib /usr/local/lib
  PATH_SUFFIXES carla)

find_program(
  CarlaUtils_BRIDGE_LV2_GTK3
  NAMES carla-bridge-lv2-gtk3
  HINTS ${CarlaUtils_LIBRARY}
  PATHS /usr/lib /usr/local/lib
  PATH_SUFFIXES carla)

find_program(
  CarlaUtils_BRIDGE_NATIVE
  NAMES carla-bridge-native
  HINTS ${CarlaUtils_LIBRARY}
  PATHS /usr/lib /usr/local/lib
  PATH_SUFFIXES carla)

find_program(
  CarlaUtils_DISCOVERY_NATIVE
  NAMES carla-discovery-native
  HINTS ${CarlaUtils_LIBRARY}
  PATHS /usr/lib /usr/local/lib
  PATH_SUFFIXES carla)

if(CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin|Windows")
  set(CarlaUtils_ERROR_REASON "Ensure that obs-deps is provided as part of CMAKE_PREFIX_PATH.")
elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux|FreeBSD")
  set(CarlaUtils_ERROR_REASON "Ensure that carla is installed on the system.")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  CarlaUtils
  FOUND_VAR CarlaUtils_FOUND
  REQUIRED_VARS CarlaUtils_INCLUDE_DIR CarlaUtils_LIBRARY CarlaUtils_BRIDGE_NATIVE CarlaUtils_DISCOVERY_NATIVE
                REASON_FAILURE_MESSAGE "${CarlaUtils_ERROR_REASON}")
mark_as_advanced(CarlaUtils_INCLUDE_DIR CarlaUtils_LIBRARY CarlaUtils_BRIDGE_NATIVE CarlaUtils_DISCOVERY_NATIVE)
unset(CarlaUtils_ERROR_REASON)

if(CarlaUtils_FOUND)
  set(CarlaUtils_INCLUDE_DIRS ${CarlaUtils_INCLUDE_DIR} ${CarlaUtils_INCLUDE_DIR}/includes
                              ${CarlaUtils_INCLUDE_DIR}/utils)
  set(CarlaUtils_LIBRARIES ${CarlaUtils_LIBRARY})

  if(NOT TARGET carla::utils)
    if(IS_ABSOLUTE "${CarlaUtils_LIBRARIES}")
      add_library(carla::utils UNKNOWN IMPORTED GLOBAL)
      set_target_properties(carla::utils PROPERTIES IMPORTED_LOCATION "${CarlaUtils_LIBRARIES}")
    else()
      add_library(carla::utils INTERFACE IMPORTED GLOBAL)
      set_target_properties(carla::utils PROPERTIES IMPORTED_LIBNAME "${CarlaUtils_LIBRARIES}")
    endif()

    set_target_properties(carla::utils PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${CarlaUtils_INCLUDE_DIRS}")
  endif()

  if(NOT TARGET carla::bridge-lv2-gtk2)
    add_executable(carla::bridge-lv2-gtk2 IMPORTED GLOBAL)
    set_target_properties(carla::bridge-lv2-gtk2 PROPERTIES IMPORTED_LOCATION "${CarlaUtils_BRIDGE_LV2_GTK2}")
    add_dependencies(carla::utils carla::bridge-lv2-gtk2)
  endif()

  if(NOT TARGET carla::bridge-lv2-gtk3)
    add_executable(carla::bridge-lv2-gtk3 IMPORTED GLOBAL)
    set_target_properties(carla::bridge-lv2-gtk3 PROPERTIES IMPORTED_LOCATION "${CarlaUtils_BRIDGE_LV2_GTK3}")
    add_dependencies(carla::utils carla::bridge-lv2-gtk3)
  endif()

  if(NOT TARGET carla::bridge-native)
    add_executable(carla::bridge-native IMPORTED GLOBAL)
    set_target_properties(carla::bridge-native PROPERTIES IMPORTED_LOCATION "${CarlaUtils_BRIDGE_NATIVE}")
    add_dependencies(carla::utils carla::bridge-native)
  endif()

  if(NOT TARGET carla::discovery-native)
    add_executable(carla::discovery-native IMPORTED GLOBAL)
    set_target_properties(carla::discovery-native PROPERTIES IMPORTED_LOCATION "${CarlaUtils_DISCOVERY_NATIVE}")
    add_dependencies(carla::utils carla::discovery-native)
  endif()
endif()

include(FeatureSummary)
set_package_properties(
  CarlaUtils PROPERTIES
  URL "https://kx.studio/Applications:Carla"
  DESCRIPTION "Carla Plugin Host")
