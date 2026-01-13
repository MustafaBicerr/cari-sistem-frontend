import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AccountListItem extends StatelessWidget {
  final String name;
  final String? phone;
  final double balance; // Pozitif: Alacaklıyız, Negatif: Borçluyuz
  final VoidCallback onTap;
  final VoidCallback onQuickAction; // Whatsapp veya Arama için

  const AccountListItem({
    super.key,
    required this.name,
    this.phone,
    required this.balance,
    required this.onTap,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDebtor = balance > 0; // Bize borcu var
    final balanceColor =
        balance == 0
            ? AppColors.textSecondary
            : (!isDebtor ? AppColors.error : AppColors.success);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar / Baş Harf
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              radius: 24,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // İsim ve Telefon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Bakiye Durumu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Bakiye",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  "₺${balance.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: balanceColor,
                  ),
                ),
                Text(
                  balance == 0
                      ? "Borcu Yok"
                      : (isDebtor ? "Borçlu" : "Alacaklı"),
                  style: TextStyle(
                    fontSize: 11,
                    color: balanceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Hızlı İşlem (Ok)
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
