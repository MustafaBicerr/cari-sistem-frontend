import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FinancialStatCard extends StatelessWidget {
  final String title;
  final String mainValue; // Ana Tutar (Örn: Kasadaki Para)
  final String subValueLabel; // Alt bilgi etiketi (Örn: "Toplam İşlem Hacmi")
  final String subValue; // Alt bilgi tutarı (Örn: "₺15.000")
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDebtCard; // Borç kartı ise rengi ve stili ona göre ayarlarız

  const FinancialStatCard({
    super.key,
    required this.title,
    required this.mainValue,
    required this.subValueLabel,
    required this.subValue,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDebtCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ÜST KISIM (İkon ve Başlık) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // --- ORTA KISIM (Ana Değer) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                mainValue,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color:
                      isDebtCard
                          ? Colors.red
                          : AppColors.textPrimary, // Borçsa kırmızı
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // --- ALT KISIM (Footer - Detay Bilgisi) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05), // Hafif renkli zemin
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subValueLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    subValue,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color, // İkon rengiyle uyumlu
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
