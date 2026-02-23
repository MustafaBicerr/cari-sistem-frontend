import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum InfoDialogType { success, error, warning, info }

class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final InfoDialogType type;

  const InfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = "Tamam",
    this.type = InfoDialogType.info,
  });

  // 🔥 EKSİK OLAN STATİK METOD
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String
    message, // UI'da 'content' yerine 'message' diyorsan burayı güncelle
    InfoDialogType type = InfoDialogType.info,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => InfoDialog(title: title, content: message, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    switch (type) {
      case InfoDialogType.success:
        iconColor = AppColors.success;
        iconData = Icons.check_circle;
        break;
      case InfoDialogType.error:
        iconColor = AppColors.error;
        iconData = Icons.error;
        break;
      case InfoDialogType.warning:
        iconColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case InfoDialogType.info:
      default:
        iconColor = AppColors.primary;
        iconData = Icons.info;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Tamam"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
