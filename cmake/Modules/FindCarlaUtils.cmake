# Once done these will be defined:
#
# CARLAUTILS_FOUND CARLAUTILS_INCLUDE_DIRS CARLAUTILS_LIBRARIES

# QUIET
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
  pkg_check_modules(_CARLAUTILS carla-utils)
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(_lib_suffix 64)
else()
  set(_lib_suffix 32)
endif()

find_path(
  CARLAUTILS_INCLUDE_DIR
  NAMES utils/CarlaBridgeUtils.hpp
  HINTS ENV CARLAUTILS_PATH ${CARLAUTILS_PATH} ${CMAKE_SOURCE_DIR}/${CARLAUTILS_PATH} ${_CARLAUTILS_INCLUDE_DIRS}
  PATHS /usr/include/carla /usr/local/include/carla /opt/local/include/carla /sw/include/carla
  PATH_SUFFIXES carla)

find_library(
  CARLAUTILS_LIBRARY
  NAMES carla_utils libcarla_utils
  HINTS ENV CARLAUTILS_PATH ${CARLAUTILS_PATH} ${CMAKE_SOURCE_DIR}/${CARLAUTILS_PATH} ${_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla /opt/local/lib/carla /sw/lib/carla
  PATH_SUFFIXES
    lib${_lib_suffix}
    lib
    libs${_lib_suffix}
    libs
    bin${_lib_suffix}
    bin
    ../lib${_lib_suffix}
    ../lib
    ../libs${_lib_suffix}
    ../libs
    ../bin${_lib_suffix}
    ../bin)

find_program(
  CARLAUTILS_BRIDGE_NATIVE
  NAMES carla-bridge-native
  HINTS ENV CARLAUTILS_PATH ${CARLAUTILS_PATH} ${CMAKE_SOURCE_DIR}/${CARLAUTILS_PATH} ${_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla /opt/local/lib/carla /sw/lib/carla
  PATH_SUFFIXES
    lib${_lib_suffix}
    lib
    libs${_lib_suffix}
    libs
    bin${_lib_suffix}
    bin
    ../lib${_lib_suffix}
    ../lib
    ../libs${_lib_suffix}
    ../libs
    ../bin${_lib_suffix}
    ../bin)

find_program(
  CARLAUTILS_DISCOVERY_NATIVE
  NAMES carla-discovery-native
  HINTS ENV CARLAUTILS_PATH ${CARLAUTILS_PATH} ${CMAKE_SOURCE_DIR}/${CARLAUTILS_PATH} ${_CARLAUTILS_LIBRARY_DIRS}
  PATHS /usr/lib/carla /usr/local/lib/carla /opt/local/lib/carla /sw/lib/carla
  PATH_SUFFIXES
    lib${_lib_suffix}
    lib
    libs${_lib_suffix}
    libs
    bin${_lib_suffix}
    bin
    ../lib${_lib_suffix}
    ../lib
    ../libs${_lib_suffix}
    ../libs
    ../bin${_lib_suffix}
    ../bin)

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
