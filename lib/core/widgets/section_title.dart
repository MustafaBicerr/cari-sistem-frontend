import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

/// A simple styled heading used above form sections.
class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.h2);
  }
}
