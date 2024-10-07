import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_recorder_example/ui/fft_painter.dart';
import 'package:flutter_recorder_example/ui/vu_meter.dart';
import 'package:flutter_recorder_example/ui/wave_painter.dart';

/// Visualizer for audio data
class Bars extends StatefulWidget {
  const Bars({super.key});

  @override
  State<Bars> createState() => BarsState();
}

class BarsState extends State<Bars> with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  late double vuMeter;
  late double db;

  @override
  void initState() {
    super.initState();
    vuMeter = 0.0;
    db = 0.0;
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
        /// 100 = scale to minimum decibel
        db = Recorder.instance.getVolumeDb();
        vuMeter = (db.abs() / 100.0).clamp(0, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

              VuMeter(
                width: 50,
                height: 256,
                vuMeter: vuMeter,
                db: db,
              ),

              const SizedBox(width: 8),

          /// FFT and wave audio data.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// FFT
              ColoredBox(
                color: const Color.fromARGB(255, 55, 55, 55),
                child: RepaintBoundary(
                  child: ClipRRect(
                    child: CustomPaint(
                      key: UniqueKey(),
                      size: const Size(320, 124),
                      painter: const FftPainter(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              /// Wave
              ColoredBox(
                color: const Color.fromARGB(255, 55, 55, 55),
                child: RepaintBoundary(
                  child: ClipRRect(
                    child: CustomPaint(
                      key: UniqueKey(),
                      size: const Size(320, 124),
                      painter: const WavePainter(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
