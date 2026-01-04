import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pmpml_app/constant/constant_ui.dart';
import 'ui.dart'; // ✅ Import the constant UI file

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 8));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UIScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'lib/assets/image/animation.json',
                  width: 300,
                  height: 300,
                ),
                const SizedBox(height: 20),
                const Text(
                  '~ Developed By Team Sparkles',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
