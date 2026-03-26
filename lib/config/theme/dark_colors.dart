import 'package:flutter/material.dart';


/// ===============================
/// Main Brand Colors (Dark Mode)
/// ===============================

// Primary Red (Logo)
Color darkGreen6B() => const Color(0xFFC40000);
Color darkGreenA5() => const Color(0xFFFF6B6B);

// Dark Red (Headers / AppBar)
Color darkBlueA6() => const Color(0xFF8B0000);

// Gradient (Primary Buttons / Headers)
LinearGradient greenGradint() => LinearGradient(
  colors: [
    darkGreen6B(),
    darkGreenA5(),
  ],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);

// Drawer background
Color darkGreen56 = const Color(0xFF7A0000);


/// ===============================
/// Grey Shades (Dark UI)
/// ===============================

Color darkGreyE5 = const Color(0xFFE0E0E0);
Color darkGreyF6 = const Color(0xFFDADADA);
Color darkGreyA3 = const Color(0xFFA3A3A3);
Color darkGrey45 = const Color(0xFF2A2A2A);
Color darkGrey48 = const Color(0xFF8A8A8A);
Color darkGrey4A = const Color(0xFF4A4A4A);
Color darkGrey3A = const Color(0xFF3A3A3A);
Color darkGrey1C = const Color(0xFF1C1C1C);
Color darkGrey12 = const Color(0xFF121212);
Color darkGrey1A = const Color(0xFF1A1A1A);
Color darkGrey26 = const Color(0xFF1E1E1E);

LinearGradient darkGreyGradint = LinearGradient(
  colors: [
    Colors.black.withOpacity(.85),
    Colors.black.withOpacity(0),
  ],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);


/// ===============================
/// Semantic Colors
/// ===============================

// Error
Color darkRed6B = const Color(0xFFFF4D4D);

// Warning (Gold Accent)
Color darkYellow00 = const Color(0xFFD4AF37);

// Info / Alert
Color darkOrange3C = const Color(0xFFFF8C42);


/// ===============================
/// Status / Success
/// ===============================

// Success
Color darkGreen3F = const Color(0xFF2ECC71);

// Action / Link
Color darkGreen3C = const Color(0xFFC40000);

// Completed / Approved
Color darkGreen8A = const Color(0xFF27AE60);


/// ===============================
/// Extra Accent Colors
/// ===============================

Color darkCyan8A = const Color(0xFF16A085);
Color darkBlueE8 = const Color(0xFFE53935);
Color darkBlue7F = const Color(0xFFB71C1C);
Color darkYellow2C = const Color(0xFFFFD700);
