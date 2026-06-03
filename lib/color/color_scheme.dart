import 'package:flutter/material.dart';

class ColorTheme {
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF2C5364),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Keep original const definitions so unedited files continue to compile
  static const Color neonLabelColor = Color(0xFF00FFFF);

  static const Shadow neonLabelGlow = Shadow(
    color: Color(0xFF00FFFF),
    blurRadius: 5,
  );

  // Dynamic active accent color for custom settings & player customization
  static Color activeNeonColor = const Color(0xFF00FFFF);

  static Shadow get activeNeonGlow => Shadow(
        color: activeNeonColor,
        blurRadius: 5,
      );

  static const Map<String, Color> presets = {
    'Cyan Neon': Color(0xFF00FFFF),
    'Emerald Pulse': Color(0xFF00FF88),
    'Purple Haze': Color(0xFFD000FF),
    'Amber Glow': Color(0xFFFFB300),
  };

  static void setPreset(String presetName) {
    if (presets.containsKey(presetName)) {
      activeNeonColor = presets[presetName]!;
    }
  }
}
