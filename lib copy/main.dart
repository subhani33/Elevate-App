import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'screens/get_started_page.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';
import 'screens/main_dashboard.dart';
import 'services/auth_service.dart';
import 'services/gpt_service.dart';
import 'services/social_media_service.dart';
import 'services/analytics_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GptService()),
        ChangeNotifierProvider(create: (_) => SocialMediaService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
      ],
      child: const ElevateApp(),
    ),
  );
}

class ElevateApp extends StatelessWidget {
  const ElevateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elevate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GetStartedPage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/dashboard': (context) => const MainDashboard(),
      },
    );
  }
}

class LandscapePainter extends CustomPainter {
  final double progress;

  LandscapePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Replace with Color.fromRGBO for better precision
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height);

    for (var i = 0; i <= size.width; i += 30) {
      final x = i.toDouble();
      final normalizedX = x / size.width;
      final amplitude = math.sin(normalizedX * math.pi * 2) * 100 * progress;
      final y = size.height - amplitude;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 