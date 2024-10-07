import 'package:flutter/material.dart';

class VuMeter extends StatelessWidget {
  const VuMeter({
    super.key,
    required this.width,
    required this.height,
    required this.vuMeter,
    required this.db,
  });

  final double width;
  final double height;
  final double vuMeter;
  final double db;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
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
            width: width,
            height: height * vuMeter,
            color: const Color.fromARGB(255, 55, 55, 55),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              db.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
