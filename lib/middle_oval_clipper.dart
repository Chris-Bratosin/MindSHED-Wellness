import 'package:flutter/material.dart';

class MiddleOvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Top arc
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.5,   // control point X
      size.height * 0.15, // control point Y
      size.width,
      0,
    );

    // Down the right edge
    path.lineTo(size.width, size.height);

    // Bottom arc
    path.quadraticBezierTo(
      size.width * 0.5,   // control point X
      size.height * 0.85, // control point Y
      0,
      size.height,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}