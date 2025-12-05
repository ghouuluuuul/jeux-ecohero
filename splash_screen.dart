import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database_service.dart';
import 'auth/login_page.dart';
import 'menu/games_menu_page.dart';
import 'intro_video_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Laisser le splash visible 2 secondes
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (!mounted) return;

    // Choisir la page finale (menu ou login)
    Widget nextPage;

    if (userId != null) {
      final user = await DatabaseService.instance.getUser(userId);
      if (user != null) {
        nextPage = GamesMenuPage(user: user);
      } else {
        nextPage = const LoginPage();
      }
    } else {
      nextPage = const LoginPage();
    }

    if (!mounted) return;

    // Lancer ensuite la vidéo d'intro, qui mènera vers nextPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => IntroVideoPage(nextPage: nextPage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.games, size: 120, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'bolbol Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Jouez, Apprenez, Gagnez',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 50),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
