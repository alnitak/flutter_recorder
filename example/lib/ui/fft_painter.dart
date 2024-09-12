// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

/// Custom painter to draw the FFT data.
class FftPainter extends CustomPainter {
  const FftPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fftData = Recorder.instance.getFft();
    final barWidth = size.width / 256;

    final paint = Paint()
      ..color = Colors.yellow;

    for (var i = 0; i < 256; i++) {
      late final double barHeight;
      barHeight = size.height * fftData[i];
      canvas.drawRect(
        Rect.fromLTWH(
          barWidth * i,
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FftPainter oldDelegate) {
    return true;
  }
}
