import 'package:flutter/material.dart';

class AppColors {
  // Dark Mode Colors
  static const List<Color> darkGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
  ];
  static const List<Color> blackGradient = [
    Color(0xFF000000),
    // Color(0xFF1E293B),
  ];
  static const List<Color> darkbottomnav = [
     Color(0x80000000), // Colors.black.withOpacity(0.5)
     Color(0x1A808080), // Colors.grey.withOpacity(0.1)
     Color(0x80000000), // Colors.black.withOpacity(0.5)
  ];

  static const List<Color> lightbottomnav = [
     Color.fromARGB(204, 255, 255, 255), // Colors.black.withOpacity(0.5)
     Color.fromARGB(250, 255, 255, 255), // Colors.grey.withOpacity(0.1)
     // Colors.black.withOpacity(0.5)
  ];

  static const Color darkText = Colors.white;
  static const Color darkPrimary = Color(0xFF1E293B);

  // Light Mode Colors
  static const List<Color> lightGradient = [
    Colors.white, // Light blue-gray at top
    // Colors.white,
    Color.fromARGB(121, 156, 191, 224) // Soft blue at the bottom
  ];

  static const Color lightText = Colors.black;
  static const Color lightPrimary = Color(0xFFE1F5FE);

  static const lightButton = Color(0xFF8B07FF);
  static const darkButton = Colors.white;
  // Common Colors
  static const Color accent = Color(0xFF4CAF50);
}
