import 'dart:math' as math;

import 'package:digital_library/core/app_colors.dart';
import 'package:digital_library/screens/categories_screen.dart';
import 'package:flutter/material.dart';

class ConfirmationScreen extends StatefulWidget {
  final int bookCount;

  const ConfirmationScreen({
    super.key,
    required this.bookCount,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _messageController;
  late Animation<double> _messageScaleAnimation;
  List<Confetti> _confetti = [];
  bool _confettiInitialized = false;

  @override
  void initState() {
    super.initState();

    // Create confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Create message animation
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _messageScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_messageController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_confettiInitialized) {
      // Generate confetti pieces
      final random = math.Random();
      final screenWidth = MediaQuery.of(context).size.width;

      _confetti = List.generate(100, (i) {
        return Confetti(
          color: Color.fromRGBO(
            random.nextInt(255),
            random.nextInt(255),
            random.nextInt(255),
            1,
          ),
          position: Offset(
            random.nextDouble() * screenWidth,
            -20 - random.nextDouble() * 100,
          ),
          size: 8 + random.nextDouble() * 12,
          velocity: Offset(
            (random.nextDouble() * 2 - 1) * 3,
            2 + random.nextDouble() * 4,
          ),
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() * 2 - 1) * 0.2,
        );
      });

      // Start animations
      _confettiController.forward();
      _messageController.forward();

      _confettiInitialized = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _backToWelcome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CategoriesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            "assets/images/category_screen_bg.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: AppColors.white),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            "assets/images/tata_logo.png",
                            height: 80,
                          ),
                          Image.asset(
                            "assets/images/logo.png",
                            height: 70,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.08,
                decoration: BoxDecoration(color: AppColors.primary),
                child: Text(
                  "Leadership Forum 2025",
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white),
                ),
              ),
            ],
          ),

          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              for (var confetti in _confetti) {
                confetti.position += confetti.velocity;
                confetti.rotation += confetti.rotationSpeed;
              }

              return CustomPaint(
                painter: ConfettiPainter(_confetti),
                child: Container(),
              );
            },
          ),

          // Content
          Center(
            child: ScaleTransition(
              scale: _messageScaleAnimation,
              child: Container(
                margin: EdgeInsets.only(top: 100),
                width: MediaQuery.of(context).size.width * 0.55,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(width: 5, color: AppColors.primary),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/check_icon.png",
                          width: 90,
                          height: 90,
                        ),
                        const SizedBox(width: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Thank you!",
                              style: TextStyle(
                                  fontSize: 44, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Your PDFs have been sent via Email! 🥳",
                              style: TextStyle(fontSize: 28),
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 60),
                    Text(
                      "Total PDFs Selected: ${widget.bookCount}",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Center(
              child: ElevatedButton(
                onPressed: () => _backToWelcome(),
                style: ElevatedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.white,
                    width: 2.0,
                  ),
                  minimumSize: Size(160, 38),
                  elevation: 0,
                  backgroundColor: AppColors.white.withValues(alpha: 0.7),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  "Back to Start",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class Confetti {
  Color color;
  Offset position;
  double size;
  Offset velocity;
  double rotation;
  double rotationSpeed;

  Confetti({
    required this.color,
    required this.position,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;

  ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confetti) {
      final paint = Paint()..color = piece.color;

      canvas.save();
      canvas.translate(piece.position.dx, piece.position.dy);
      canvas.rotate(piece.rotation);

      // Draw confetti piece as a rectangle
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: piece.size, height: piece.size),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return true;
  }
}
