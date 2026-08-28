// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

/// Custom painter to draw the FFT data.
class FftPainter extends CustomPainter {
  const FftPainter({this.data});

  final AudioVisualizationData? data;

  @override
  void paint(Canvas canvas, Size size) {
    if (!Recorder.instance.isDeviceStarted() ||
        data == null ||
        data!.fft.isEmpty) {
      return;
    }

    final channels = data!.fft;
    final channelCount = channels.length;
    final channelWidth = size.width / channelCount;

    for (var c = 0; c < channelCount; c++) {
      final fftData = channels[c];
      if (fftData.isEmpty) continue;

      final barWidth = channelWidth / fftData.length;
      final paint = Paint()
        ..color = channelCount == 1
            ? Colors.yellow
            : (c == 0 ? Colors.yellow : Colors.cyan);

      final leftOffset = c * channelWidth;
      for (var i = 0; i < fftData.length; i++) {
        final barHeight = (size.height * fftData[i]).clamp(0.0, size.height);
        canvas.drawRect(
          Rect.fromLTWH(
            leftOffset + barWidth * i,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FftPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
