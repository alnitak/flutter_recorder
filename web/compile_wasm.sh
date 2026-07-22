#!/bin/bash
set -euo pipefail

shopt -s extglob

rm -f libflutter_recorder_plugin.*
rm -rf build
mkdir build
cd build

# Avoid pulling in the host macOS/iOS SDK headers when emscripten is invoked.
unset CPATH
unset CFLAGS
unset CXXFLAGS
unset CPPFLAGS
unset LDFLAGS
unset SDKROOT
unset SYSROOT

# Set up temporary include directories so <opus/opus.h> and <ogg/ogg.h> resolve
# to the vendored xiph sources. A config_types.h is generated because Ogg's
# os_types.h requires it on platforms it doesn't explicitly recognise.
mkdir -p include
ln -s ../../../xiph/opus/include include/opus
mkdir -p include/ogg
ln -s ../../../../xiph/ogg/include/ogg/ogg.h include/ogg/ogg.h
ln -s ../../../../xiph/ogg/include/ogg/os_types.h include/ogg/os_types.h
cat > include/ogg/config_types.h << 'EOF'
#ifndef __CONFIG_TYPES_H__
#define __CONFIG_TYPES_H__
#include <stdint.h>
typedef int16_t ogg_int16_t;
typedef uint16_t ogg_uint16_t;
typedef int32_t ogg_int32_t;
typedef uint32_t ogg_uint32_t;
typedef int64_t ogg_int64_t;
typedef uint64_t ogg_uint64_t;
#endif /* __CONFIG_TYPES_H__ */
EOF

#https://emscripten.org/docs/tools_reference/emcc.html
#-g3 #keep debug info, including JS whitespace, function names

emcc -O3 \
-DENABLE_ASSERTIONS=1 \
-DUSE_ALLOCA=1 \
-DOPUS_BUILD=1 \
-I ../../src/fft \
-I ../../src \
-I include \
-I include/opus \
-I ../../xiph/opus/celt \
-I ../../xiph/opus/silk \
-I ../../xiph/opus/silk/float \
-I ../../xiph/opus/src \
../../src/flutter_recorder.cpp \
../../src/capture.cpp \
../../src/analyzer.cpp \
../../src/opus_encoder_pipeline.cpp \
../../src/opus_ogg_writer.cpp \
../../src/fft/soloud_fft.cpp \
../../src/filters/filters.cpp \
../../src/filters/autogain.cpp \
../../src/filters/echo_cancellation.cpp \
../../xiph/ogg/src/bitwise.c \
../../xiph/ogg/src/framing.c \
../../xiph/opus/src/opus.c \
../../xiph/opus/src/opus_encoder.c \
../../xiph/opus/src/opus_decoder.c \
../../xiph/opus/src/opus_multistream.c \
../../xiph/opus/src/opus_multistream_encoder.c \
../../xiph/opus/src/opus_multistream_decoder.c \
../../xiph/opus/src/opus_projection_encoder.c \
../../xiph/opus/src/opus_projection_decoder.c \
../../xiph/opus/src/repacketizer.c \
../../xiph/opus/src/extensions.c \
../../xiph/opus/src/analysis.c \
../../xiph/opus/src/mlp.c \
../../xiph/opus/src/mlp_data.c \
../../xiph/opus/src/mapping_matrix.c \
../../xiph/opus/silk/*.c \
../../xiph/opus/silk/float/*.c \
../../xiph/opus/celt/!(opus_custom_demo).c \
-s MODULARIZE=1 -s EXPORT_NAME="'RecorderModule'" \
-msimd128 -msse3 \
-s "EXPORTED_RUNTIME_METHODS=['ccall','cwrap']" \
-s "EXPORTED_FUNCTIONS=['_free', '_malloc']" \
-s EXPORT_ALL=1 \
-s NO_EXIT_RUNTIME=1 \
-s SAFE_HEAP=1 \
-s STACK_SIZE=4194304 \
-s ALLOW_TABLE_GROWTH=1 \
-s ALLOW_MEMORY_GROWTH=1 \
-o ../../web/libflutter_recorder_plugin.js
