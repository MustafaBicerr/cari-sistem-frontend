import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// A convenient card wrapper used for grouping related form sections.
///
/// Provides consistent padding, margin and rounded borders.
class SectionCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    this.color = Colors.white,
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: padding, child: child),
    );
  }
}
