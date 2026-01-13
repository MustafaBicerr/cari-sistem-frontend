import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler (Primary)
  static const Color primary = Color(0xFF00BFA5); // Veteriner Yeşili/Turkuazı
  static const Color primaryDark = Color(0xFF008E76);
  static const Color primaryLight = Color(0xFF5DF2D6);

  // İkincil Renkler (Secondary/Accent)
  static const Color accent = Color(
    0xFFFF6F00,
  ); // Turuncu (Action Buttonlar için)

  // Arka Planlar
  static const Color background = Color(0xFFF5F7FA); // Hafif gri/beyaz
  static const Color surface = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF5F7FA);

  // Metin Renkleri
  static const Color textPrimary = Color(0xFF1A1A1A); // Koyu Siyah
  static const Color textSecondary = Color(0xFF757575); // Gri
  static const Color textHint = Color(0xFFBDBDBD);

  // Durum Renkleri (Success, Error, Warning)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF2196F3);

  // Border ve Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
}
