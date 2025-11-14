import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    // 🎨 Animation du fond (dégradé bleu animé)
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // 🔵 Animation du logo (fade + zoom)
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    // Lancer le logo légèrement après le fond
    Future.delayed(const Duration(milliseconds: 400), () {
      _logoController.forward();
    });

    // Redirection automatique vers la page de connexion
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => LoginPage(),
          transitionsBuilder: (_, anim, __, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeInOut);
            return FadeTransition(opacity: curve, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(Colors.blue.shade300, Colors.blue.shade700,
                      _backgroundAnimation.value)!,
                  Color.lerp(Colors.blue.shade700, Colors.indigo.shade900,
                      _backgroundAnimation.value)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 💎 Effet de halo doux derrière le logo
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🖼️ Logo animé
                ScaleTransition(
                  scale: _logoAnimation,
                  child: FadeTransition(
                    opacity: _logoAnimation,
                    child: Image.asset(
                      'assets/logo.png',
                      width: size.width * 0.45,
                    ),
                  ),
                ),

                // 🕓 Texte animé de chargement
                Positioned(
                  bottom: size.height * 0.15,
                  child: FadeTransition(
                    opacity: _logoAnimation,
                    child: Column(
                      children: const [
                        Text(
                          "Chargement...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
