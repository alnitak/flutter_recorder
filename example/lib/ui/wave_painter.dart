import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

/// Custom painter to draw the wave data.
class WavePainter extends CustomPainter {
  const WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final waveData = Recorder.instance.getWave();

    final barWidth = size.width / 256;
    final paint = Paint()
      ..color = Colors.yellow;

    for (var i = 0; i < 256; i++) {
      late final double barHeight;
      barHeight = size.height * waveData[i];
      canvas.drawRect(
        Rect.fromLTWH(
          barWidth * i,
          (size.height - barHeight) / 2,
          barWidth,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }
}
