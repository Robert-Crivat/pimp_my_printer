import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double zoom;
  final Offset offset;

  GridPainter({required this.zoom, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 0.5;

    final center = size.center(Offset.zero) + offset;
    final gridSize = 50 * zoom;

    if (gridSize < 5) return; // Non disegnare la griglia se è troppo piccola

    // Disegna le linee verticali
    for (double x = center.dx % gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double x = center.dx % gridSize - gridSize; x >= 0; x -= gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Disegna le linee orizzontali
    for (double y = center.dy % gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double y = center.dy % gridSize - gridSize; y >= 0; y -= gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Assi X e Y
    final axisPaint = Paint()..strokeWidth = 2.0;
    // Asse X (rosso)
    canvas.drawLine(
        center,
        center.translate(100 * zoom, 0),
        axisPaint..color = Colors.red);
    // Asse Y (verde)
    canvas.drawLine(
        center,
        center.translate(0, 100 * zoom),
        axisPaint..color = Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
