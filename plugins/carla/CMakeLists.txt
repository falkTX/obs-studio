cmake_minimum_required(VERSION 3.16...3.25)

option(ENABLE_CARLA "Enable building OBS with carla plugin host" ON)

if(NOT ENABLE_CARLA)
  if(OBS_CMAKE_VERSION VERSION_GREATER_EQUAL 3.0.0)
    target_disable(carla)
  else()
    message(STATUS "OBS:  DISABLED   carla")
  endif()
  return()
endif()

# Find carla utils
if(APPLE)
  # even though cmake finds the framework, it refuses to work with it. let's force it
  find_library(CARLAUTILS_FRAMEWORK NAMES carla-utils)
  get_filename_component(CARLAUTILS_LIBRARY_DIR "${CARLAUTILS_FRAMEWORK}/.." ABSOLUTE)
  message("Found carla-utils: ${CARLAUTILS_LIBRARY_DIR} ${CARLAUTILS_FRAMEWORK}")
  add_library(carla::utils INTERFACE IMPORTED)
  set_target_properties(
    carla::utils
    PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${CARLAUTILS_FRAMEWORK}/Headers"
               INTERFACE_LINK_OPTIONS "-F${CARLAUTILS_LIBRARY_DIR}"
               INTERFACE_LINK_LIBRARIES $<LINK_LIBRARY:FRAMEWORK,carla-utils.framework>)
  set_property(GLOBAL APPEND PROPERTY _OBS_FRAMEWORKS "${CARLAUTILS_FRAMEWORK}")
else()
  find_package(CarlaUtils)
  if(NOT CARLAUTILS_FOUND)
    if(OBS_CMAKE_VERSION VERSION_GREATER_EQUAL 3.0.0)
      target_disable(carla)
    else()
      message(STATUS "OBS:  DISABLED   carla (carla-utils library not found)")
    endif()
    return()
  endif()
endif()

# Find Qt
find_qt(COMPONENTS Core Widgets)

# Setup carla-bridge target
add_library(carla-bridge MODULE)
add_library(OBS::carla-bridge ALIAS carla-bridge)

target_compile_definitions(carla-bridge PRIVATE CARLA_MODULE_ID="carla-bridge" CARLA_MODULE_NAME="Audio Plugin"
                                                CARLA_UTILS_USE_QT)

target_link_libraries(carla-bridge PRIVATE carla::utils OBS::libobs Qt::Core Qt::Widgets $<$<C_COMPILER_ID:GNU>:dl>)

target_sources(
  carla-bridge
  PRIVATE carla.c
          carla-bridge.cpp
          carla-bridge-wrapper.cpp
          common.c
          pluginlistdialog.cpp
          pluginrefreshdialog.hpp
          qtutils.cpp)

if(OBS_CMAKE_VERSION VERSION_GREATER_EQUAL 3.0.0)
  set_target_properties_obs(
    carla-bridge
    PROPERTIES AUTOMOC ON
               AUTOUIC ON
               AUTORCC ON
               FOLDER plugins
               PREFIX "")
else()
  set_target_properties(
    carla-bridge
    PROPERTIES AUTOMOC ON
               AUTOUIC ON
               AUTORCC ON
               FOLDER plugins
               PREFIX "")
  setup_plugin_target(carla-bridge)
endif()

# Setup carla-patchbay target (only available for certain systems)
if(PKGCONFIG_FOUND AND NOT (OS_MACOS OR OS_WINDOWS))
  pkg_check_modules(carla-host-plugin IMPORTED_TARGET QUIET carla-host-plugin)
  if(carla-host-plugin_FOUND)
    add_library(carla-patchbay MODULE)
    add_library(OBS::carla-patchbay ALIAS carla-patchbay)

    target_compile_definitions(carla-patchbay PRIVATE CARLA_MODULE_ID="carla-patchbay"
                                                      CARLA_MODULE_NAME="Carla Patchbay")

    target_link_libraries(carla-patchbay PRIVATE OBS::libobs Qt::Core Qt::Widgets PkgConfig::carla-host-plugin)

    target_sources(carla-patchbay PRIVATE carla.c carla-patchbay-wrapper.c common.c qtutils.cpp)

    if(OBS_CMAKE_VERSION VERSION_GREATER_EQUAL 3.0.0)
      set_target_properties_obs(carla-patchbay PROPERTIES FOLDER plugins PREFIX "")
    else()
      set_target_properties(carla-patchbay PROPERTIES FOLDER plugins PREFIX "")
      setup_plugin_target(carla-patchbay)
    endif()
  endif()
endif()
