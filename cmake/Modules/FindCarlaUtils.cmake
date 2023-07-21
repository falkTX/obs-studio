# Once done these will be defined:
#
# CARLAUTILS_FOUND CARLAUTILS_INCLUDE_DIRS CARLAUTILS_LIBRARIES

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
  PATHS /usr/lib/carla /usr/local/lib/carla /app/lib/carla
  PATH_SUFFIXES carla)

find_program(
  CARLAUTILS_BRIDGE_NATIVE
  NAMES carla-bridge-native
  HINTS ${PC_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla /app/bin
  PATH_SUFFIXES carla)

find_program(
  CARLAUTILS_DISCOVERY_NATIVE
  NAMES carla-discovery-native
  HINTS ${PC_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla /app/bin
  PATH_SUFFIXES carla)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  CarlaUtils
  FOUND_VAR CARLAUTILS_FOUND
  REQUIRED_VARS CARLAUTILS_INCLUDE_DIR CARLAUTILS_LIBRARY CARLAUTILS_BRIDGE_NATIVE CARLAUTILS_DISCOVERY_NATIVE)
mark_as_advanced(CARLAUTILS_INCLUDE_DIR CARLAUTILS_LIBRARY CARLAUTILS_BRIDGE_NATIVE CARLAUTILS_DISCOVERY_NATIVE)

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
