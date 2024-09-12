import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Class to construct an uncompressed 32bit BMP image from raw data.
/// Used by me internally, do no use elsewhere!!§°çéé**#¼¬
class Bmp32Header {
  late int width;
  late int height;
  late Uint8List bmp;
  late int contentSize;
  int rgba32HeaderSize = 122;
  int bytesPerPixel = 4;

  /// set a BMP from bytes
  Bmp32Header.setBmp(Uint8List imgBytes) {
    final bd = imgBytes.buffer.asByteData();
    width = bd.getInt32(0x12, Endian.little);
    height = -bd.getInt32(0x16, Endian.little);
    contentSize = bd.getInt32(0x02, Endian.little) - rgba32HeaderSize;
    bmp = imgBytes;
  }

  /// set BMP header and memory to use
  Bmp32Header.setHeader(this.width, this.height) {
    contentSize = width * height;
    bmp = Uint8List(rgba32HeaderSize + contentSize * bytesPerPixel);

    bmp.buffer.asByteData()
      ..setUint8(0x00, 0x42) // 'B'
      ..setUint8(0x01, 0x4d) // 'M'

      ..setInt32(0x02, rgba32HeaderSize + contentSize, Endian.little)
      ..setInt32(0x0A, rgba32HeaderSize, Endian.little)
      ..setUint32(0x0E, 108, Endian.little)
      ..setUint32(0x12, width, Endian.little)
      ..setUint32(0x16, -height, Endian.little)
      ..setUint16(0x1A, 1, Endian.little)
      ..setUint8(0x1C, 32)
      ..setUint32(0x1E, 3, Endian.little)
      ..setUint32(0x22, contentSize, Endian.little)
      ..setUint32(0x36, 0x000000ff, Endian.little)
      ..setUint32(0x3A, 0x0000ff00, Endian.little)
      ..setUint32(0x3E, 0x00ff0000, Endian.little)
      ..setUint32(0x42, 0xff000000, Endian.little);
  }

  /// Insert the [bitmap] after the header and return the BMP
  Uint8List storeBitmap(Uint8List bitmap) {
    bmp.setRange(rgba32HeaderSize, bmp.length, bitmap);
    return bmp;
  }

  /// clear BMP pixels leaving the header untouched
  Uint8List clearBitmap() {
    bmp.fillRange(rgba32HeaderSize, bmp.length, 0);
    return bmp;
  }

  Color getPixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return Colors.transparent;
    int px = rgba32HeaderSize + ((y * width + x) << 2);
    Color ret = Color.fromARGB(
      bmp[px + 3],
      bmp[px],
      bmp[px + 1],
      bmp[px + 2],
    );
    return ret;
  }

  void setPixel(int x, int y, Color color) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    int px = rgba32HeaderSize + ((y * width + x) << 2);
    bmp[px] = color.red;
    bmp[px + 1] = color.green;
    bmp[px + 2] = color.blue;
    bmp[px + 3] = color.alpha;
  }

  /// set BMP pixels color
  Uint8List setBitmapBackgroundColor(int r, int g, int b, int a) {
    final value = ((r & 0xff) |
            ((g & 0xff) << 8) |
            ((b & 0xff) << 16) |
            ((a & 0xff) << 24)) &
        0xFFFFFFFF;
    final tmp = bmp.sublist(rgba32HeaderSize).buffer.asUint32List();
    tmp.fillRange(0, tmp.length, value);

    final bytes = BytesBuilder()
      ..add(bmp.sublist(0, rgba32HeaderSize))
      ..add(tmp.buffer.asUint8List());
    // ignore: join_return_with_assignment
    bmp = bytes.toBytes();

    return bmp;
  }
}
