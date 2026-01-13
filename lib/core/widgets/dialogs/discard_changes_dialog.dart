import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DiscardChangesDialog extends StatelessWidget {
  final VoidCallback onDiscard; // Değişiklikleri at ve çık

  const DiscardChangesDialog({super.key, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Değişiklikler Kaybolacak",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: const Text(
        "Yaptığınız değişiklikleri kaydetmeden çıkmak istediğinize emin misiniz?",
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Dialogu kapat, formda kal
          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          child: const Text("Hayır, Kal"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Dialogu kapat
            onDiscard(); // Formu kapat (işlemi tetikle)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: const Text("Evet, Çık"),
        ),
      ],
    );
  }
}
