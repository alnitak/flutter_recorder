import 'dart:typed_data';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioDataContainer', () {
    test('length and rawData getters', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final container = AudioDataContainer(bytes);

      expect(container.length, 8);
      expect(container.rawData, bytes);
    });

    group('toU8List', () {
      test('from u8 returns original Uint8List', () {
        final bytes = Uint8List.fromList([0, 128, 255]);
        final container = AudioDataContainer(bytes);
        expect(container.toU8List(from: PCMFormat.u8), bytes);
      });

      test('from s16le converts correctly', () {
        // s16le samples: -32768 (min -> 0), 0 (mid -> 128), 32767 (max -> 255)
        final s16List = Int16List.fromList([-32768, 0, 32767]);
        final container = AudioDataContainer(s16List.buffer.asUint8List());

        final result = container.toU8List(from: PCMFormat.s16le);
        expect(result.length, 3);
        expect(result[0], 0);
        expect(result[1], 128);
        expect(result[2], 255);
      });

      test('from f32le converts correctly', () {
        final f32List = Float32List.fromList([-1.0, 0.0, 1.0]);
        final container = AudioDataContainer(f32List.buffer.asUint8List());

        final result = container.toU8List(from: PCMFormat.f32le);
        expect(result.length, 3);
        expect(result[0], 1); // (-1.0 * 127 + 128) = 1
        expect(result[1], 128); // (0.0 * 127 + 128) = 128
        expect(result[2], 255); // (1.0 * 127 + 128) = 255
      });
    });

    group('toS8List', () {
      test('from u8 converts to s8 correctly', () {
        final bytes = Uint8List.fromList([0, 128, 255]);
        final container = AudioDataContainer(bytes);

        final result = container.toS8List(from: PCMFormat.u8);
        expect(result.length, 3);
        expect(result[0], -128);
        expect(result[1], 0);
        expect(result[2], 127);
      });

      test('from f32le converts to s8 correctly', () {
        final f32List = Float32List.fromList([-1.0, 0.0, 1.0]);
        final container = AudioDataContainer(f32List.buffer.asUint8List());

        final result = container.toS8List(from: PCMFormat.f32le);
        expect(result.length, 3);
        expect(result[0], -127);
        expect(result[1], 0);
        expect(result[2], 127);
      });
    });

    group('toS16List', () {
      test('from s16le returns a zero-copy view', () {
        final s16List = Int16List.fromList([-32768, 0, 32767]);
        final bytes = s16List.buffer.asUint8List();
        final container = AudioDataContainer(bytes);

        final result = container.toS16List(from: PCMFormat.s16le);
        expect(result, equals(s16List));
        expect(result.buffer, bytes.buffer);
      });

      test('from f32le converts correctly', () {
        final f32List = Float32List.fromList([-1.0, 0.0, 1.0]);
        final container = AudioDataContainer(f32List.buffer.asUint8List());

        final result = container.toS16List(from: PCMFormat.f32le);
        expect(result[0], -32767);
        expect(result[1], 0);
        expect(result[2], 32767);
      });
    });

    group('toS24List', () {
      test('from s24le returns zero-copy Int8List view', () {
        final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]);
        final container = AudioDataContainer(bytes);

        final result = container.toS24List(from: PCMFormat.s24le);
        expect(result.length, 6);
        expect(result.buffer, bytes.buffer);
      });
    });

    group('toS32List', () {
      test('from s32le returns a zero-copy view', () {
        final s32List = Int32List.fromList([-2147483648, 0, 2147483647]);
        final bytes = s32List.buffer.asUint8List();
        final container = AudioDataContainer(bytes);

        final result = container.toS32List(from: PCMFormat.s32le);
        expect(result, equals(s32List));
        expect(result.buffer, bytes.buffer);
      });
    });

    group('toF32List', () {
      test('from f32le returns a zero-copy view', () {
        final f32List = Float32List.fromList([-1.0, 0.0, 1.0]);
        final bytes = f32List.buffer.asUint8List();
        final container = AudioDataContainer(bytes);

        final result = container.toF32List(from: PCMFormat.f32le);
        expect(result, equals(f32List));
        expect(result.buffer, bytes.buffer);
      });

      test('from s16le converts correctly', () {
        final s16List = Int16List.fromList([-32768, 0, 32767]);
        final container = AudioDataContainer(s16List.buffer.asUint8List());

        final result = container.toF32List(from: PCMFormat.s16le);
        expect(result[0], -1.0);
        expect(result[1], 0.0);
        expect(result[2], closeTo(1.0, 0.0001));
      });
    });
  });
}
