# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_recorder_library VERSION 0.0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/fft)

# Ogg/Opus include and library paths for non-Apple platforms.
# On iOS/macOS the podspec provides the XCFrameworks and headers.
if (NOT APPLE)
  if (ANDROID)
    set(OGGOPUS_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../android/include")
    set(OGGOPUS_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../android/libs/${ANDROID_ABI}")
  elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(OGGOPUS_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../linux/include")
    set(OGGOPUS_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../linux/libs")
  elseif (WIN32)
    set(OGGOPUS_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../windows/include")
    set(OGGOPUS_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../windows/libs")
  else()
    set(OGGOPUS_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../include")
    set(OGGOPUS_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../libs")
  endif()
  if (NOT IS_DIRECTORY "${OGGOPUS_INCLUDE_DIR}")
    message(FATAL_ERROR "Ogg/Opus include directory not found: ${OGGOPUS_INCLUDE_DIR}. Build the xiph scripts first.")
  endif()
  if (NOT IS_DIRECTORY "${OGGOPUS_LIBRARY_DIR}")
    message(FATAL_ERROR "Ogg/Opus library directory not found: ${OGGOPUS_LIBRARY_DIR}. Build the xiph scripts first.")
  endif()
  include_directories(${OGGOPUS_INCLUDE_DIR})
endif()

add_library(flutter_recorder SHARED
  "flutter_recorder.cpp"
  "analyzer.cpp"
  "capture.cpp"
  "opus_encoder_pipeline.cpp"
  "opus_ogg_writer.cpp"
  "fft/soloud_fft.cpp"
  "filters/filters.cpp"
  "filters/autogain.cpp"
  "filters/echo_cancellation.cpp"
)

set_target_properties(flutter_recorder PROPERTIES
  PUBLIC_HEADER flutter_recorder.h
  OUTPUT_NAME "flutter_recorder"
)

target_compile_definitions(flutter_recorder PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(flutter_recorder PRIVATE "-Wl,-z,max-page-size=16384,-O2")
  target_link_libraries(flutter_recorder log)
endif()

if (NOT APPLE)
  if (ANDROID)
    # On Android the prebuilt shared libraries live under libs/<abi>.
    # They are renamed to avoid conflicts with other plugins that also ship
    # libogg/libopus (e.g. flutter_soloud).
    set(OGG_LIBRARY "${OGGOPUS_LIBRARY_DIR}/libfr_ogg.so")
    set(OPUS_LIBRARY "${OGGOPUS_LIBRARY_DIR}/libfr_opus.so")
    if (NOT EXISTS "${OGG_LIBRARY}")
      message(FATAL_ERROR "libfr_ogg not found in ${OGGOPUS_LIBRARY_DIR}")
    endif()
    if (NOT EXISTS "${OPUS_LIBRARY}")
      message(FATAL_ERROR "libfr_opus not found in ${OGGOPUS_LIBRARY_DIR}")
    endif()
  else()
    find_library(OGG_LIBRARY NAMES ogg PATHS ${OGGOPUS_LIBRARY_DIR} NO_DEFAULT_PATH)
    find_library(OPUS_LIBRARY NAMES opus PATHS ${OGGOPUS_LIBRARY_DIR} NO_DEFAULT_PATH)
    if (NOT OGG_LIBRARY)
      message(FATAL_ERROR "libogg not found in ${OGGOPUS_LIBRARY_DIR}")
    endif()
    if (NOT OPUS_LIBRARY)
      message(FATAL_ERROR "libopus not found in ${OGGOPUS_LIBRARY_DIR}")
    endif()
  endif()
  target_link_libraries(flutter_recorder ${OGG_LIBRARY} ${OPUS_LIBRARY})
  set(OGG_LIBRARY "${OGG_LIBRARY}" PARENT_SCOPE)
  set(OPUS_LIBRARY "${OPUS_LIBRARY}" PARENT_SCOPE)
endif()
