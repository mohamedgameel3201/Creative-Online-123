import 'package:flutter/material.dart';

/// ===============================
/// Main Brand Colors (Logo Based)
/// ===============================

// Primary Red (Logo)
Color lightGreen77() => const Color(0xFFC40000);
Color lightGreen91() => const Color(0xFFFF4D4D);

// Dark Red (Headers / AppBar)
Color lightBlue64() => const Color(0xFF8B0000);

// Gradient (Primary Buttons / Headers)
LinearGradient greenGradint() => LinearGradient(
  colors: [
    lightGreen77(),
    lightGreen91(),
  ],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);

// Drawer background
Color lightGreen63 = const Color(0xFFB30000);


/// ===============================
/// Grey Shades (UI / Text)
/// ===============================

Color lightGrey33 = const Color(0xFF1F1F1F);
Color lightGrey3A = const Color(0xFF2A2A2A);
Color lightGrey5E = const Color(0xFF5E5E5E);
Color lightGreyD0 = const Color(0xFFD0D0D0);
Color lightGreyB2 = const Color(0xFFB2B2B2);
Color lightGreyA5 = const Color(0xFFA5A5A5);
Color lightGreyCF = const Color(0xFFCFCFCF);
Color lightGreyE7 = const Color(0xFFE7E7E7);
Color lightGreyF8 = const Color(0xFFF8F8F8);
Color lightGreyFA = const Color(0xFFFAFAFA);

// Overlay Gradient (Images / Cards)
LinearGradient lightGreyGradint = LinearGradient(
  colors: [
    Colors.black.withOpacity(.75),
    Colors.black.withOpacity(0),
  ],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);


/// ===============================
/// Semantic Colors
/// ===============================

// Error
Color lightRed49 = const Color(0xFFFF4949);

// Warning (Gold from logo)
Color lightYellow29 = const Color(0xFFD4AF37);

// Info / Alert
Color lightOrange50 = const Color(0xFFFF8C42);


/// ===============================
/// Status / Success
/// ===============================

// Success
Color lightGreen50 = const Color(0xFF2ECC71);

// Link / Action
Color lightGreen4B = const Color(0xFFC40000);

// Completed / Approved
Color lightGreen9D = const Color(0xFF27AE60);


/// ===============================
/// Extra Accent Colors
/// ===============================

Color lightCyan50 = const Color(0xFF16A085);
Color lightBlueFE = const Color(0xFFE53935);
Color lightBlueA4 = const Color(0xFFB71C1C);
Color lightYellow4C = const Color(0xFFFFD700);
