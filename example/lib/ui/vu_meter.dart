import 'package:flutter/material.dart';

class VuMeter extends StatelessWidget {
  const VuMeter({
    super.key,
    required this.width,
    required this.height,
    required this.vuMeter,
  });

  final double width;
  final double height;
  final double vuMeter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 20,
          height: 256,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green,
                Colors.red,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Container(
          width: 20,
          height: 256 * vuMeter,
          color: Colors.black,
        ),
      ],
    );
  }
}
