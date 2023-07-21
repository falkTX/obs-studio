#[=======================================================================[.rst
FindCarlaUtils
----------

FindModule for carla-utils and associated libraries

Result Variables
^^^^^^^^^^^^^^^^

This module sets the following variables:

``CARLAUTILS_FOUND``
  True, if all required components and the core library were found.

Cache variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``CARLAUTILS_LIBRARIES``
  Path to the library component of carla-utils
``CARLAUTILS_INCLUDE_DIRS``
  Directories used by carla-utils.

#]=======================================================================]

include(FindPackageHandleStandardArgs)

find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
  pkg_check_modules(PC_CARLAUTILS QUIET carla-utils)
endif()

find_path(
  CARLAUTILS_INCLUDE_DIR
  NAMES utils/CarlaBridgeUtils.hpp
  HINTS ${PC_CARLAUTILS_INCLUDE_DIRS}
  PATHS /usr/include/carla /usr/local/include/carla
  PATH_SUFFIXES carla
  DOC "carla include directory")

find_library(
  CARLAUTILS_LIBRARY
  NAMES carla_utils libcarla_utils
  HINTS ${PC_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla
  PATH_SUFFIXES carla)

find_program(
  CARLAUTILS_BRIDGE_NATIVE
  NAMES carla-bridge-native
  HINTS ${PC_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla
  PATH_SUFFIXES carla)

find_program(
  CARLAUTILS_DISCOVERY_NATIVE
  NAMES carla-discovery-native
  HINTS ${PC_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla
  PATH_SUFFIXES carla)

if(CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin|Windows")
  set(CARLAUTILS_ERROR_REASON "Ensure that obs-deps is provided as part of CMAKE_PREFIX_PATH.")
elseif(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux|FreeBSD")
  set(CARLAUTILS_ERROR_REASON "Ensure that carla is installed on the system.")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  CarlaUtils
  FOUND_VAR CARLAUTILS_FOUND
  REQUIRED_VARS CARLAUTILS_INCLUDE_DIR CARLAUTILS_LIBRARY CARLAUTILS_BRIDGE_NATIVE CARLAUTILS_DISCOVERY_NATIVE
  REASON_FAILURE_MESSAGE "${CARLAUTILS_ERROR_REASON}")
mark_as_advanced(CARLAUTILS_INCLUDE_DIR CARLAUTILS_LIBRARY CARLAUTILS_BRIDGE_NATIVE CARLAUTILS_DISCOVERY_NATIVE)
unset(CARLAUTILS_ERROR_REASON)

if(CARLAUTILS_FOUND)
  set(CARLAUTILS_INCLUDE_DIRS ${CARLAUTILS_INCLUDE_DIR} ${CARLAUTILS_INCLUDE_DIR}/includes
                              ${CARLAUTILS_INCLUDE_DIR}/utils)
  set(CARLAUTILS_LIBRARIES ${CARLAUTILS_LIBRARY})

  if(NOT TARGET carla::utils)
    if(IS_ABSOLUTE "${CARLAUTILS_LIBRARIES}")
      add_library(carla::utils UNKNOWN IMPORTED GLOBAL)
      set_target_properties(carla::utils PROPERTIES IMPORTED_LOCATION "${CARLAUTILS_LIBRARIES}")
    else()
      add_library(carla::utils INTERFACE IMPORTED GLOBAL)
      set_target_properties(carla::utils PROPERTIES IMPORTED_LIBNAME "${CARLAUTILS_LIBRARIES}")
    endif()

    set_target_properties(carla::utils PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${CARLAUTILS_INCLUDE_DIRS}")
  endif()

  if(NOT TARGET carla::bridge-native)
    add_executable(carla::bridge-native IMPORTED GLOBAL)
    set_target_properties(carla::bridge-native PROPERTIES IMPORTED_LOCATION "${CARLAUTILS_BRIDGE_NATIVE}")
    add_dependencies(carla::utils carla::bridge-native)
  endif()

  if(NOT TARGET carla::discovery-native)
    add_executable(carla::discovery-native IMPORTED GLOBAL)
    set_target_properties(carla::discovery-native PROPERTIES IMPORTED_LOCATION "${CARLAUTILS_DISCOVERY_NATIVE}")
    add_dependencies(carla::utils carla::discovery-native)
  endif()
endif()

include(FeatureSummary)
set_package_properties(
  CARLAUTILS PROPERTIES
  URL "https://kx.studio/Applications:Carla"
  DESCRIPTION "Carla Plugin Host")
