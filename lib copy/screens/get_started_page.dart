import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../particles/particle_system.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _transformAnimation;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final List<String> _socialPlatforms = [
    'assets/linkedin_logo.svg',
    'assets/instagram_logo.svg',
    'assets/twitter_logo.svg',
    'assets/facebook_logo.svg',
  ];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(); // Make the animation repeat continuously

    _transformAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Listen to page changes
    _pageController.addListener(() {
      int newPage = _pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A237E), // Deep blue
                  const Color(0xFF3949AB), // Medium blue
                  const Color(0xFF3F51B5).withOpacity(0.8), // Lighter blue
                ],
              ),
            ),
          ),
          
          // Particle effect background
          const ParticleSystem(),
          
          // Main content with SingleChildScrollView to prevent overflow
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Flexible content area that can be scrolled
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: _buildHeader(),
                        ),
                        const SizedBox(height: 20),
                        _build3DTransformingLandscape(),
                        const SizedBox(height: 30),
                        _buildFeatureCarousel(),
                        
                        // Spacer to push the button to bottom if there's enough space
                        const SizedBox(height: 120), // Added extra space to ensure button is not cut off
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Position the button at the bottom with elevation
          Positioned(
            left: 0,
            right: 0,
            bottom: 40, // Raised from the bottom
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildGetStartedButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Elevate text with star icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Elevate',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Add star icon next to text
              Icon(
                Icons.star,
                color: Colors.white,
                size: 28,
              ).animate().fadeIn().scale(),
            ],
          ).animate().fadeIn().scale(),
          const SizedBox(height: 16),
          const Text(
            'Transform Your Social Presence',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          const Text(
            'AI-powered optimization for all your social media platforms',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _build3DTransformingLandscape() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating profile icon as the central element
        SizedBox(
          height: 260,
          child: RotatingProfileIcon(
            size: 180,
            controller: _controller,
          ),
        ),
        // Social platform orbiting animation
        AnimatedBuilder(
          animation: _transformAnimation,
          builder: (context, child) {
            return SizedBox(
              height: 260, // Larger size
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ..._socialPlatforms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final platform = entry.value;
                    
                    // Create continuous 3D rotation effect
                    final angle = 2 * math.pi * (index / _socialPlatforms.length + _transformAnimation.value);
                    
                    // Orbit radius
                    final radius = 130.0;
                    
                    // Add some vertical movement for 3D effect
                    final verticalOffset = 15 * math.sin(_transformAnimation.value * 2 * math.pi + index * math.pi / 2);
                    
                    // Calculate position
                    final dx = math.cos(angle) * radius;
                    final dy = math.sin(angle) * radius + verticalOffset;
                    
                    // Add slight perspective effect
                    final perspective = 0.8 + 0.2 * math.cos(angle);
                    
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 + dx - 25,
                      top: 130 + dy - 25,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Add perspective
                          ..scale(perspective)
                          ..rotateZ(angle)
                          ..rotateY(_transformAnimation.value * 2 * math.pi),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                              )
                            ]
                          ),
                          child: SvgPicture.asset(
                            platform,
                            height: 40,
                            width: 40,
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  // Connection lines between platforms
                  CustomPaint(
                    size: const Size(300, 260),
                    painter: ConnectionsPainter(
                      progress: 1.0,
                      angle: _transformAnimation.value * 2 * math.pi,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView(
            controller: _pageController,
            children: [
              _build3DFeatureCard(
                'Smart Optimization',
                'AI analyzes your content and suggests improvements',
                Icons.auto_awesome,
                Colors.blue.shade300,
              ),
              _build3DFeatureCard(
                'Cross-Platform Sync',
                'Manage all your social media from one place',
                Icons.sync,
                Colors.purple.shade300,
              ),
              _build3DFeatureCard(
                'Analytics Dashboard',
                'Track your growth and engagement metrics',
                Icons.analytics,
                Colors.green.shade300,
              ),
              _build3DFeatureCard(
                'Content Generation',
                'Create engaging posts with AI assistance',
                Icons.create,
                Colors.orange.shade300,
              ),
            ],
          ),
        ),
        // Carousel indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) => 
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index 
                    ? const Color(0xFF6B4EFF) 
                    : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _build3DFeatureCard(String title, String description, IconData icon, Color accentColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              accentColor.withOpacity(0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D effect for the icon
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateX(0.1)
                  ..rotateY(0.1),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn()
      .slideY(begin: 0.2, duration: 600.ms)
      .then(delay: 200.ms)
      .shimmer(duration: 1800.ms);
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigate to login page
        Navigator.pushNamed(context, '/login');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        shadowColor: const Color(0xFF6B4EFF).withOpacity(0.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded),
        ],
      ),
    ).animate()
      .fadeIn(delay: 900.ms)
      .slideY(begin: 0.2)
      .then()
      .shimmer(delay: 1500.ms);
  }
}

// Custom painter for drawing connections between platforms
class ConnectionsPainter extends CustomPainter {
  final double progress;
  final double angle;
  
  ConnectionsPainter({required this.progress, this.angle = 0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 130.0;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw connection lines between platforms
    for (int i = 0; i < 4; i++) {
      for (int j = i + 1; j < 4; j++) {
        final angle1 = 2 * math.pi * (i / 4 + angle / (2 * math.pi));
        final angle2 = 2 * math.pi * (j / 4 + angle / (2 * math.pi));
        
        final x1 = center.dx + math.cos(angle1) * radius;
        final y1 = center.dy + math.sin(angle1) * radius;
        final x2 = center.dx + math.cos(angle2) * radius;
        final y2 = center.dy + math.sin(angle2) * radius;
        
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter oldDelegate) => 
    oldDelegate.progress != progress || oldDelegate.angle != angle;
}

// New widget for rotating profile icon
class RotatingProfileIcon extends StatelessWidget {
  final double size;
  final AnimationController controller;

  const RotatingProfileIcon({
    super.key,
    required this.size,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Create a continuous 360-degree rotation
        return Transform.rotate(
          angle: controller.value * 2 * math.pi,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF6B4EFF),  // Center color - primary app color
                  Color(0xFF3949AB),  // Edge color
                ],
                stops: [0.2, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4EFF).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(), // ensure continuous animation
        ).rotate(
          duration: 3.seconds,
          curve: Curves.easeInOut,
        );
      },
    );
  }
} 