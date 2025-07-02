# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_recorder_library VERSION 0.0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/fft)

add_library(flutter_recorder SHARED
  "flutter_recorder.cpp"
  "analyzer.cpp"
  "capture.cpp"
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
