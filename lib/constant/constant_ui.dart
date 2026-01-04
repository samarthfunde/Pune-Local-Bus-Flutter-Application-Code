import 'package:flutter/material.dart';

// Gradient background widget
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

// Title text style
const TextStyle titleTextStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

// Input field decoration
final InputDecoration inputDecorationStyle = InputDecoration(
  fillColor: Colors.white.withOpacity(0.4),
  filled: true,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide.none,
  ),
);

// Primary button style
final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: Colors.pinkAccent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
);

// Error text style
const TextStyle errorTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.red,
  fontWeight: FontWeight.w500,
);
