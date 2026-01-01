import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  // Breakpointler (Kırılma Noktaları)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    // Desktop varsa ve genişlik uygunsa -> Desktop Tasarımı
    if (size.width >= 1100 && desktop != null) {
      return desktop!;
    }

    // Tablet varsa ve genişlik uygunsa -> Tablet Tasarımı
    if (size.width >= 600 && tablet != null) {
      return tablet!;
    }

    // Hiçbiri yoksa -> Mobile (Varsayılan)
    return mobile;
  }
}
