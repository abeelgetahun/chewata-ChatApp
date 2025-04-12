import 'dart:ui';

import 'package:flutter/material.dart';


class CurvedBorderPainter extends CustomPainter {
  final double progress;
  final double segmentLength;
  final double cornerRadius;

  CurvedBorderPainter(
    this.progress, {
    this.segmentLength = 60.0,
    this.cornerRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a path that represents the rounded rectangle border
    final roundedRectPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ));

    // Calculate metrics to get the exact path length
    final PathMetrics pathMetrics = roundedRectPath.computeMetrics();
    final PathMetric pathMetric = pathMetrics.first;
    final double totalLength = pathMetric.length;

    // Calculate the starting position based on progress
    final double startDistance = (progress * totalLength) % totalLength;

    // Extract the path segment
    Path extractedPath = _extractPathSegment(
      pathMetric,
      startDistance,
      segmentLength,
      totalLength,
    );

    // Create a gradient shader that fades at both ends
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.lightGreen.withOpacity(1.0),
          Colors.lightGreen.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw the extracted path
    canvas.drawPath(extractedPath, paint);

    // Add a subtle glow effect
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.lightGreen.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(extractedPath, glowPaint);

    // Add a shadow effect on the page
    final Paint shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 50 // Larger stroke for shadow
      ..color = Colors.lightGreen.withOpacity(0.1) // Light green shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30); // Blurred shadow

    canvas.drawPath(extractedPath, shadowPaint);
  }

  Path _extractPathSegment(
    PathMetric pathMetric,
    double startDistance,
    double segmentLength,
    double totalLength,
  ) {
    Path extractedPath = Path();

    // Handle the case where the segment wraps around the end of the path
    if (startDistance + segmentLength <= totalLength) {
      // Simple case - segment doesn't wrap around
      extractedPath = pathMetric.extractPath(
        startDistance,
        startDistance + segmentLength,
      );
    } else {
      // Segment wraps around - extract two parts and combine
      final firstPart = pathMetric.extractPath(
        startDistance,
        totalLength,
      );

      final secondPart = pathMetric.extractPath(
        0,
        segmentLength - (totalLength - startDistance),
      );

      extractedPath = Path()
        ..addPath(firstPart, Offset.zero)
        ..addPath(secondPart, Offset.zero);
    }

    return extractedPath;
  }

  @override
  bool shouldRepaint(covariant CurvedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.segmentLength != segmentLength ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}