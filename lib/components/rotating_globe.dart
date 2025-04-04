import 'package:flutter/material.dart';
import 'dart:math' as math;

class RotatingGlobe extends StatefulWidget {
  final double size;
  final bool enableTilt;

  const RotatingGlobe({
    super.key,
    required this.size,
    this.enableTilt = true,
  });

  @override
  State<RotatingGlobe> createState() => _RotatingGlobeState();
}

class _RotatingGlobeState extends State<RotatingGlobe>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  final double _baseRotationSpeed = 0.02;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.enableTilt ? _handlePanUpdate : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Continuously rotate the globe around Y axis
          final rotationValue = _controller.value * 2 * math.pi * _baseRotationSpeed * 50;
          
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateX(_rotationX)
              ..rotateY(_rotationY + rotationValue),
            child: _buildGlobe(),
          );
        },
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      // Update rotation based on drag
      _rotationY += details.delta.dx * 0.01;
      _rotationX -= details.delta.dy * 0.01;
      
      // Limit X rotation to avoid flipping
      _rotationX = _rotationX.clamp(-0.5, 0.5);
    });
  }

  Widget _buildGlobe() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0xFF3949AB),  // Center color
            Color(0xFF1A237E),  // Edge color
          ],
          stops: [0.2, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x663949AB),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: GlobePainter(),
        size: Size(widget.size, widget.size),
      ),
    );
  }
}

class GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw latitude lines
    final latPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 1; i < 6; i++) {
      final latRadius = radius * i / 6;
      canvas.drawCircle(center, latRadius, latPaint);
    }
    
    // Draw longitude lines (meridians)
    final longPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x1 = center.dx + radius * math.cos(angle);
      final y1 = center.dy + radius * math.sin(angle);
      final x2 = center.dx - radius * math.cos(angle);
      final y2 = center.dy - radius * math.sin(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), longPaint);
    }
    
    // Draw some "continent" blobs
    final landPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // North America
    final naPath = Path();
    naPath.moveTo(center.dx - radius * 0.3, center.dy - radius * 0.3);
    naPath.quadraticBezierTo(
      center.dx - radius * 0.5, center.dy - radius * 0.5,
      center.dx - radius * 0.4, center.dy - radius * 0.7
    );
    naPath.quadraticBezierTo(
      center.dx - radius * 0.3, center.dy - radius * 0.8,
      center.dx - radius * 0.1, center.dy - radius * 0.6
    );
    naPath.quadraticBezierTo(
      center.dx - radius * 0.1, center.dy - radius * 0.4,
      center.dx - radius * 0.3, center.dy - radius * 0.3
    );
    canvas.drawPath(naPath, landPaint);
    
    // Europe/Asia
    final euPath = Path();
    euPath.moveTo(center.dx + radius * 0.1, center.dy - radius * 0.3);
    euPath.quadraticBezierTo(
      center.dx + radius * 0.3, center.dy - radius * 0.5,
      center.dx + radius * 0.5, center.dy - radius * 0.4
    );
    euPath.quadraticBezierTo(
      center.dx + radius * 0.7, center.dy - radius * 0.3,
      center.dx + radius * 0.6, center.dy - radius * 0.1
    );
    euPath.quadraticBezierTo(
      center.dx + radius * 0.5, center.dy,
      center.dx + radius * 0.3, center.dy - radius * 0.1
    );
    euPath.quadraticBezierTo(
      center.dx + radius * 0.1, center.dy - radius * 0.2,
      center.dx + radius * 0.1, center.dy - radius * 0.3
    );
    canvas.drawPath(euPath, landPaint);
    
    // Africa
    final afPath = Path();
    afPath.moveTo(center.dx + radius * 0.1, center.dy + radius * 0.1);
    afPath.quadraticBezierTo(
      center.dx + radius * 0.3, center.dy,
      center.dx + radius * 0.3, center.dy + radius * 0.3
    );
    afPath.quadraticBezierTo(
      center.dx + radius * 0.2, center.dy + radius * 0.5,
      center.dx, center.dy + radius * 0.4
    );
    afPath.quadraticBezierTo(
      center.dx - radius * 0.1, center.dy + radius * 0.3,
      center.dx - radius * 0.1, center.dy + radius * 0.1
    );
    afPath.quadraticBezierTo(
      center.dx, center.dy,
      center.dx + radius * 0.1, center.dy + radius * 0.1
    );
    canvas.drawPath(afPath, landPaint);
    
    // South America
    final saPath = Path();
    saPath.moveTo(center.dx - radius * 0.2, center.dy + radius * 0.1);
    saPath.quadraticBezierTo(
      center.dx - radius * 0.1, center.dy + radius * 0.3,
      center.dx - radius * 0.3, center.dy + radius * 0.5
    );
    saPath.quadraticBezierTo(
      center.dx - radius * 0.4, center.dy + radius * 0.4,
      center.dx - radius * 0.4, center.dy + radius * 0.2
    );
    saPath.quadraticBezierTo(
      center.dx - radius * 0.3, center.dy + radius * 0.1,
      center.dx - radius * 0.2, center.dy + radius * 0.1
    );
    canvas.drawPath(saPath, landPaint);
    
    // Australia
    final auPath = Path();
    auPath.addOval(Rect.fromCenter(
      center: Offset(center.dx + radius * 0.6, center.dy + radius * 0.5),
      width: radius * 0.3,
      height: radius * 0.2,
    ));
    canvas.drawPath(auPath, landPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 