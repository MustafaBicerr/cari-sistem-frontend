import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SaleProductSearch extends StatelessWidget {
  final Function(String) onSearch;
  final VoidCallback onScanTap;

  const SaleProductSearch({
    super.key,
    required this.onSearch,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              autofocus: true, // Sayfa açılınca direkt buraya odaklansın
              decoration: const InputDecoration(
                hintText: "Ürün adı ara veya barkod okut...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSubmitted:
                  onSearch, // Enter'a basınca (Barkod okuyucu enter basar)
            ),
          ),
          Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.3)),
          IconButton(
            tooltip: "Barkod Tara (Kamera)",
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: onScanTap,
          ),
        ],
      ),
    );
  }
}
