import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  late double x;
  late double y;
  late double dx;
  late double dy;
  late double size;
  late double opacity;
  late Color color;
  
  final math.Random random = math.Random();

  Particle({required Size screenSize}) {
    reset(screenSize);
    // Start particles from random positions
    y = random.nextDouble() * screenSize.height;
  }

  void reset(Size screenSize) {
    x = random.nextDouble() * screenSize.width;
    y = screenSize.height + 10;
    dx = (random.nextDouble() - 0.5) * 2;
    dy = -(2 + random.nextDouble() * 3);
    size = 1 + random.nextDouble() * 3;
    opacity = 0.1 + random.nextDouble() * 0.4;
    color = Colors.white;
  }

  void update(Size screenSize) {
    x += dx;
    y += dy;
    dy *= 0.99; // Gradually slow down vertical speed
    opacity -= 0.005;
    
    if (y < -10 || opacity <= 0) {
      reset(screenSize);
    }
  }
}

class ParticleSystem extends StatefulWidget {
  const ParticleSystem({super.key});

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  final List<Particle> particles = [];
  late AnimationController _controller;
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRandomColor() {
    final colors = [
      Colors.white,
      Colors.blue[200]!,
      Colors.purple[200]!,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  void _initializeParticles() {
    if (_screenSize == null) return;
    particles.clear();
    for (var i = 0; i < 100; i++) {
      final particle = Particle(screenSize: _screenSize!)
        ..color = _getRandomColor();
      particles.add(particle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (particles.isEmpty) {
          _initializeParticles();
        }
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: ParticlePainter(particles: particles, screenSize: _screenSize!),
            );
          },
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Size screenSize;

  ParticlePainter({required this.particles, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(screenSize);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 