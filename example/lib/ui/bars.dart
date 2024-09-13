import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_recorder_example/tools/bmp_header.dart';
import 'package:flutter_recorder_example/ui/fft_painter.dart';
import 'package:flutter_recorder_example/ui/wave_painter.dart';

/// Visualizer for audio data
class Bars extends StatefulWidget {
  const Bars({super.key});

  @override
  State<Bars> createState() => BarsState();
}

class BarsState extends State<Bars> with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  late Bmp32Header image;
  Uint8List? bmpBytes;
  late double vuMeter;

  @override
  void initState() {
    super.initState();
    image = Bmp32Header.setHeader(512, 256);
    vuMeter = 0.0;
    ticker = createTicker(_tick);
    ticker.start();
  }

  @override
  void dispose() {
    ticker.stop();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (context.mounted) {
      setState(() {
        _buildBmpImage();

        /// 60 = scale to minimum decibel
        final db = Recorder.instance.getVolumeDb();
        vuMeter = (db.abs() / 60.0);
        // print('db: $db, vuMeter: $vuMeter');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          /// FFT and wave audio data.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                color: Colors.black,
                child: RepaintBoundary(
                  child: ClipRRect(
                    child: CustomPaint(
                      key: UniqueKey(),
                      size: const Size(253, 100),
                      painter: const FftPainter(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ColoredBox(
                color: Colors.black,
                child: RepaintBoundary(
                  child: ClipRRect(
                    child: CustomPaint(
                      key: UniqueKey(),
                      size: const Size(253, 100),
                      painter: const WavePainter(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              /// VU-meter
              SizedBox(
                width: 40,
                height: 100,
                child: ColoredBox(
                  color: Colors.black,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 40,
                      height: 100 - vuMeter * 100,
                      child: const ColoredBox(color: Colors.green),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 6),

          /// Texture audio data.
          if (bmpBytes != null)
            SizedBox(
              width: 512,
              height: 256,
              child: Image.memory(
                bmpBytes!,
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }

  void _buildBmpImage() {
    final texture2D = Recorder.instance.getTexture2D();
    Uint8List b = Uint8List(512 * 256 * 4);

    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        final offset = y * 512 + x;
        b[offset * 4 + 0] = (texture2D[offset].clamp(0, 1) * 255).floor(); // R
        b[offset * 4 + 1] = 0; // G
        b[offset * 4 + 2] = 0; // B
        b[offset * 4 + 3] = 255; // A
      }
      for (var x = 256; x < 512; x++) {
        final offset = y * 512 + x;
        b[offset * 4 + 0] = 0; // R
        b[offset * 4 + 1] = (texture2D[offset] * 255).abs().floor(); // G
        b[offset * 4 + 2] = 0; // B
        b[offset * 4 + 3] = 255; // A
      }
    }
    image = Bmp32Header.setHeader(512, 256);
    bmpBytes = image.storeBitmap(b);
  }

  // Future<Image> fromPixels(Uint8List pixels, int width, int height) {
  //   assert(pixels.length == width * height * 4);
  //   final completer = Completer<Image>();
  //   decodeImageFromPixels(
  //     pixels,
  //     width,
  //     height,
  //     PixelFormat.rgba8888,
  //     (img) {
  //       completer.complete(img);
  //     },
  //   );
  //   return completer.future;
  // }
}
