#!/bin/bash
set -euo pipefail

rm -f libflutter_recorder_plugin.*
rm -rf build
mkdir build
cd build

#https://emscripten.org/docs/tools_reference/emcc.html
#-g3 #keep debug info, including JS whitespace, function names

em++ \
-I ../../src/fft \
-I ../../src \
../../src/flutter_recorder.cpp \
../../src/capture.cpp \
../../src/analyzer.cpp \
../../src/fft/soloud_fft.cpp \
-O3 \
-msimd128 -msse3 \
-s "EXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
-s "EXPORTED_FUNCTIONS=['_free', '_malloc']" \
-s EXPORT_ALL=1 -s NO_EXIT_RUNTIME=1 \
-s SAFE_HEAP=1 \
-s STACK_SIZE=4194304 \
-s ALLOW_MEMORY_GROWTH \
-o ../../web/libflutter_recorder_plugin.js
