import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class AccountListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double balance;
  final VoidCallback onTap;
  final bool isSupplier;

  const AccountListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.balance,
    required this.onTap,
    this.isSupplier = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    // Bakiye Durumu:
    // Müşteri için: Pozitif = Bize Borçlu (İyi), Negatif = Biz Borçluyuz
    // Tedarikçi için: Pozitif = Biz Borçluyuz (Kötü)
    // Renk mantığını buna göre kuralım:

    Color balanceColor;
    if (balance == 0) {
      balanceColor = Colors.grey;
    } else if (isSupplier) {
      // Tedarikçiye borcumuz varsa (Pozitif) Kırmızı, Alacağımız varsa (Negatif) Yeşil
      balanceColor = balance > 0 ? Colors.red : Colors.green;
    } else {
      // Müşteri bize borçluysa (Pozitif) Yeşil (Alacak), Biz borçluysak Kırmızı
      // Genelde muhasebede alacak pozitiftir.
      balanceColor = balance > 0 ? Colors.green : Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              isSupplier
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: TextStyle(
              color: isSupplier ? Colors.orange : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(balance.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: balanceColor,
              ),
            ),
            Text(
              balance == 0
                  ? "Bakiye Yok"
                  : (isSupplier
                      ? (balance > 0 ? "Borçlusunuz" : "Alacaklısınız")
                      : (balance > 0 ? "Borçlu" : "Alacaklı")),
              style: TextStyle(fontSize: 10, color: balanceColor),
            ),
          ],
        ),
      ),
    );
  }
}
