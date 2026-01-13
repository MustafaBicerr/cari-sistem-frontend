// c:\projects\cari_sistem\mobile\lib\features\clinic\presentation\screens\clinic_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class ClinicMenuScreen extends ConsumerStatefulWidget {
  const ClinicMenuScreen({super.key});

  @override
  ConsumerState<ClinicMenuScreen> createState() => _ClinicMenuScreenState();
}

class _ClinicMenuScreenState extends ConsumerState<ClinicMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Klinik Menüsü',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
