# The native engine is built by the Dart build hook (hook/build.dart) and
# bundled as a native code asset. This file exists only because the Flutter
# tool requires a CMakeLists.txt for Windows plugins; there is no plugin class
# and nothing left to compile here.
cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flutter_recorder")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

add_library(${PLUGIN_NAME} INTERFACE)

# List of absolute paths to libraries that should be bundled with the plugin.
# Empty: the hook-built code asset is bundled by the Flutter tool instead.
set(flutter_recorder_bundled_libraries
  ""
  PARENT_SCOPE
)
