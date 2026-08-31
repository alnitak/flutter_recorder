import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

/// Custom painter to draw the wave data.
class WavePainter extends CustomPainter {
  const WavePainter({this.data});

  final AudioVisualizationData? data;

  @override
  void paint(Canvas canvas, Size size) {
    if (!Recorder.instance.isDeviceStarted() ||
        data == null ||
        data!.wave.isEmpty) {
      return;
    }

    final channels = data!.wave;
    final channelCount = channels.length;
    final channelWidth = size.width / channelCount;

    for (var c = 0; c < channelCount; c++) {
      final waveData = channels[c];
      if (waveData.isEmpty) continue;

      final barWidth = channelWidth / waveData.length;
      final paint = Paint()
        ..color = channelCount == 1
            ? Colors.yellow
            : (c == 0 ? Colors.yellow : Colors.cyan);

      final leftOffset = c * channelWidth;
      final centerY = size.height / 2;
      for (var i = 0; i < waveData.length; i++) {
        final sample = waveData[i].clamp(-1.0, 1.0);
        final barHeight = size.height * sample.abs();
        canvas.drawRect(
          Rect.fromLTWH(
            leftOffset + barWidth * i,
            centerY - (barHeight / 2),
            barWidth,
            barHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
