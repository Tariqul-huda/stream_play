import 'package:flutter/material.dart';

class ColorTheme{
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF2C5364),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Shadow neonLabelGlow = Shadow(
  color: Color(0xFF00FFFF), // neon cyan glow
  blurRadius: 5,
  );
  static const Color neonLabelColor = Color(0xFF00FFFF);


}
