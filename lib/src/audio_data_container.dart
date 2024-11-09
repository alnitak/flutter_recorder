import 'dart:typed_data';

import 'package:flutter_recorder/src/enums.dart';
import 'package:meta/meta.dart';

/// Class that contain the streamed audio data.
///
/// The data is received a `Uint8List` whatever the format is. This raw data
/// is stored into [rawData] and its format is the one used when initializing
/// the recorder.
/// This class also provide methods to convert the data to other formats based
/// on the original recorder format. For example to convert to `Int8List` the
/// data when the recorder is initialized with `PCMFormat.f32le`, you have to
/// use [toS8List] method. Be aware that the conversion is compute expensive and
/// should be avoided if possible initializing the recorder with the format
/// desired.
class AudioDataContainer {
  /// The class which is used by the Stream to listen to the audio data.
  AudioDataContainer(this.u8Data);

  /// Raw audio data in Uint8List format.
  @internal
  final Uint8List u8Data;

  /// Return the lenght in byte of the audio data.
  int get length => u8Data.length;

  /// Get the raw audio data whatever the format.
  Uint8List get rawData => u8Data;

  // Helper method to read Int16 from Uint8List in little-endian
  int _readInt16le(int offset) =>
      (u8Data[offset] | (u8Data[offset + 1] << 8)) << 16 >> 16;

  // Helper method to read Int32 from Uint8List in little-endian
  int _readInt32le(int offset) =>
      u8Data[offset] |
      (u8Data[offset + 1] << 8) |
      (u8Data[offset + 2] << 16) |
      (u8Data[offset + 3] << 24);

  /// Convert the data to Uint8List based on the [from] format.
  Uint8List toU8List({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        return u8Data;
      case PCMFormat.s16le:
        final result = Uint8List(u8Data.length ~/ 2);
        final from = u8Data.buffer.asInt16List();
        for (var i = 0; i < result.length; i++) {
          result[i] = (from[i] + 32768) ~/ 256;
        }
        return result;
      case PCMFormat.s24le:
        final result = Uint8List(u8Data.length ~/ 3);
        for (var i = 0; i < result.length; i++) {
          result[i] = ((u8Data[i * 3] |
                      (u8Data[i * 3 + 1] << 8) |
                      (u8Data[i * 3 + 2] << 16)) >>
                  16) +
              128;
        }
        return result;
      case PCMFormat.s32le:
        final result = Uint8List(u8Data.length ~/ 4);
        for (var i = 0; i < result.length; i++) {
          result[i] = ((u8Data[i * 4] |
                      (u8Data[i * 4 + 1] << 8) |
                      (u8Data[i * 4 + 2] << 16) |
                      (u8Data[i * 4 + 3] << 24)) >>
                  24) +
              128;
        }
        return result;
      case PCMFormat.f32le:
        final result = Uint8List(u8Data.length ~/ 4);
        final f32Buffer = Float32List.view(u8Data.buffer);
        for (var i = 0; i < result.length; i++) {
          result[i] = (f32Buffer[i] * 127.0 + 128.0).clamp(0, 255).toInt();
        }
        return result;
    }
  }

  /// Convert the data to Int8List based on the [from] format.
  Int8List toS8List({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        return Int8List.fromList(u8Data.map((e) => e - 128).toList());
      case PCMFormat.s16le:
        final result = Int8List(u8Data.length ~/ 2);
        for (var i = 0; i < result.length; i++) {
          result[i] = (_readInt16le(i * 2) >> 8).clamp(-128, 127);
        }
        return result;
      case PCMFormat.s24le:
        final result = Int8List(u8Data.length ~/ 3);
        for (var i = 0; i < result.length; i++) {
          result[i] = ((u8Data[i * 3] |
                      (u8Data[i * 3 + 1] << 8) |
                      (u8Data[i * 3 + 2] << 16)) >>
                  16)
              .clamp(-128, 127);
        }
        return result;
      case PCMFormat.s32le:
        final result = Int8List(u8Data.length ~/ 4);
        for (var i = 0; i < result.length; i++) {
          result[i] = ((u8Data[i * 4] |
                      (u8Data[i * 4 + 1] << 8) |
                      (u8Data[i * 4 + 2] << 16) |
                      (u8Data[i * 4 + 3] << 24)) >>
                  24)
              .clamp(-128, 127);
        }
        return result;
      case PCMFormat.f32le:
        final result = Int8List(u8Data.length ~/ 4);
        final f32Buffer = Float32List.view(u8Data.buffer);
        for (var i = 0; i < result.length; i++) {
          result[i] = (f32Buffer[i] * 127.0).clamp(-128, 127).toInt();
        }
        return result;
    }
  }

  /// Convert the data to Int16List based on the [from] format.
  Int16List toS16List({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        final result = Int16List(u8Data.length);
        for (var i = 0; i < result.length; i++) {
          result[i] = (u8Data[i] - 128) << 8;
        }
        return result;
      case PCMFormat.s16le:
        return Int16List.view(u8Data.buffer);
      case PCMFormat.s24le:
        final result = Int16List(u8Data.length ~/ 3);
        for (var i = 0; i < result.length; i++) {
          var sample = u8Data[i * 3] |
              (u8Data[i * 3 + 1] << 8) |
              (u8Data[i * 3 + 2] << 16) |
              0xFF000000;
          if (sample >= 0x800000) {
            sample -= 0x1000000; // Subtract 2^24 to "correct" the sign
          }
          result[i] = ((sample / 16777215) * 65535).round();
        }
        return result;
      case PCMFormat.s32le:
        final result = Int16List(u8Data.length ~/ 4);
        final from = u8Data.buffer.asInt32List();
        for (var i = 0; i < result.length; i++) {
          // result[i] = (_readInt32le(i * 4) >> 16).clamp(-32768, 32767);
          result[i] = from[i] ~/ 32768;
        }
        return result;
      case PCMFormat.f32le:
        final result = Int16List(u8Data.length ~/ 4);
        final f32Buffer = Float32List.view(u8Data.buffer);
        for (var i = 0; i < result.length; i++) {
          result[i] = (f32Buffer[i] * 32767.0).clamp(-32768, 32767).toInt();
        }
        return result;
    }
  }

  /// Convert the data to Int32List based on the [from] format.
  ///
  /// Since the data is composed by 3 bytes and we want a list `Int32List`
  /// (there is not a `Int24List`), this data cannot be used for example to
  /// write a WAV file because the 1st byte of each value is 0.
  /// This is intended just to have the values. If you want to write a WAV
  /// file, use [toS24List] instead.
  Int32List toS24ListOnInt32({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        final result = Int32List(u8Data.length);
        for (var i = 0; i < u8Data.length; i++) {
          result[i] = (u8Data[i] - 128) << 16; // Convertendo da u8 a s24
        }
        return result;
      case PCMFormat.s16le:
        final result = Int32List(u8Data.length ~/ 2);
        for (var i = 0; i < result.length; i++) {
          result[i] = _readInt16le(i * 2) << 8; // Estendendo a 24 bit
        }
        return result;
      case PCMFormat.s24le:
        final result = Int32List(u8Data.length ~/ 3);
        for (var i = 0; i < result.length; i++) {
          result[i] = (u8Data[i * 3] |
                  (u8Data[i * 3 + 1] << 8) |
                  (u8Data[i * 3 + 2] << 16)) <<
              8 >>
              8; // Sign extend
        }
        return result;
      case PCMFormat.s32le:
        final result = Int32List(u8Data.length ~/ 4);
        for (var i = 0; i < result.length; i++) {
          result[i] = _readInt32le(i * 4) >> 8; // Ridurre a 24 bit
        }
        return result;
      case PCMFormat.f32le:
        final result = Int32List(u8Data.length ~/ 4);
        final f32Buffer = Float32List.view(u8Data.buffer);
        for (var i = 0; i < result.length; i++) {
          result[i] =
              (f32Buffer[i] * 8388607.0).clamp(-8388608, 8388607).toInt();
        }
        return result;
    }
  }

  /// Convert the data to Int8List based on the [from] format.
  ///
  /// Since the data is stored in 24 bits, this method will convert the data to
  /// a sequence of bytes aligned by 3 representing the 24-bit data.
  Int8List toS24List({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        // Converts from 8-bit unsigned to 24-bit signed (3 bytes per sample)
        final result = Int8List(u8Data.length * 3);
        for (var i = 0; i < u8Data.length; i++) {
          final sample = (u8Data[i] - 128) << 16; // Extend to 24 bit
          result[i * 3] = sample & 0xFF;
          result[i * 3 + 1] = (sample >> 8) & 0xFF;
          result[i * 3 + 2] = (sample >> 16) & 0xFF;
        }
        return result;

      case PCMFormat.s16le:
        // Convert from 16-bit signed to 24-bit signed
        final result = Int8List((u8Data.length ~/ 2) * 3);
        for (var i = 0; i < result.length ~/ 3; i++) {
          final sample = _readInt16le(i * 2) << 8; // Extend to 24 bit
          result[i * 3] = sample & 0xFF;
          result[i * 3 + 1] = (sample >> 8) & 0xFF;
          result[i * 3 + 2] = (sample >> 16) & 0xFF;
        }
        return result;

      case PCMFormat.s24le:
        // If the data is already 24-bit, copy it directly
        return Int8List.fromList(u8Data);

      case PCMFormat.s32le:
        // Converts from 32-bit signed to 24-bit signed, truncating the least
        // significant bytes
        final result = Int8List((u8Data.length ~/ 4) * 3);
        for (var i = 0; i < result.length ~/ 3; i++) {
          final sample = _readInt32le(i * 4) >> 8; // Trunc to 24 bit
          result[i * 3] = sample & 0xFF;
          result[i * 3 + 1] = (sample >> 8) & 0xFF;
          result[i * 3 + 2] = (sample >> 16) & 0xFF;
        }
        return result;

      case PCMFormat.f32le:
        // Convert from float32 to 24-bit signed
        final result = Int8List((u8Data.length ~/ 4) * 3);
        final f32Buffer = Float32List.view(u8Data.buffer);
        for (var i = 0; i < f32Buffer.length; i++) {
          final sample =
              (f32Buffer[i] * 8388607.0).clamp(-8388608, 8388607).toInt();
          result[i * 3] = sample & 0xFF;
          result[i * 3 + 1] = (sample >> 8) & 0xFF;
          result[i * 3 + 2] = (sample >> 16) & 0xFF;
        }
        return result;
    }
  }

  /// Convert the data to Int32List based on the [from] format.
  Int32List toS32List({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        final result = Int32List(u8Data.length);
        for (var i = 0; i < u8Data.length; i++) {
          result[i] = (u8Data[i] - 128) << 24;
        }
        return result;
      case PCMFormat.s16le:
        final result = Int32List(u8Data.length ~/ 2);
        for (var i = 0; i < result.length; i++) {
          result[i] = _readInt16le(i * 2) << 16;
        }
        return result;
      case PCMFormat.s24le:
        final result = Int32List(u8Data.length ~/ 3);
        for (var i = 0; i < result.length; i++) {
          result[i] = u8Data[i * 3] |
              (u8Data[i * 3 + 1] << 8) |
              (u8Data[i * 3 + 2] << 16) |
              0xFF000000;
          if (result[i] >= 0x800000) {
            result[i] -= 0x1000000; // Subtract 2^24 to "correct" the sign
          }
          result[i] = (result[i] * 0xFFFFFFFF) ~/ 0xFFFFFF;
        }
        return result;
      case PCMFormat.s32le:
        return Int32List.view(u8Data.buffer);
      case PCMFormat.f32le:
        final result = Int32List(u8Data.length ~/ 4);
        final f32Buffer = Float32List.view(u8Data.buffer);
        for (var i = 0; i < result.length; i++) {
          result[i] = (f32Buffer[i] * 2147483647.0)
              .clamp(-2147483648, 2147483647)
              .toInt();
        }
        return result;
    }
  }

  /// Convert the data to Float32List based on the [from] format.
  Float32List toF32List({required PCMFormat from}) {
    switch (from) {
      case PCMFormat.u8:
        final result = Float32List(u8Data.length);
        for (var i = 0; i < u8Data.length; i++) {
          result[i] = (u8Data[i] - 128) / 128.0;
        }
        return result;
      case PCMFormat.s16le:
        final result = Float32List(u8Data.length ~/ 2);
        final from = u8Data.buffer.asInt16List();
        for (var i = 0; i < result.length; i++) {
          result[i] = from[i] / 32768.0;
        }
        return result;
      case PCMFormat.s24le:
        final result = Float32List(u8Data.length ~/ 3);
        for (var i = 0; i < result.length; i++) {
          var sample = u8Data[i * 3] |
              (u8Data[i * 3 + 1] << 8) |
              (u8Data[i * 3 + 2] << 16);
          if (sample >= 0x800000) {
            sample -= 0x1000000; // Subtract 2^24 to "correct" the sign
          }
          result[i] = sample.toDouble() / 0x800000;
        }
        return result;
      case PCMFormat.s32le:
        final result = Float32List(u8Data.length ~/ 4);
        final from = u8Data.buffer.asInt32List();
        for (var i = 0; i < result.length; i++) {
          result[i] = from[i] / 2147483648.0;
        }
        return result;
      case PCMFormat.f32le:
        return Float32List.view(u8Data.buffer);
    }
  }
}
