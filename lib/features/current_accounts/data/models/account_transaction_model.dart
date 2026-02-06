import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Bu enum işlemin yönünü belirler
enum TransactionType {
  sale, // Satış (Müşteri Borçlanır 🔴)
  purchase, // Alım (Tedarikçiye Borçlanırız 🔴)
  collection, // Tahsilat (Para Girişi 🟢)
  payment, // Ödeme (Para Çıkışı 🟢)
  opening, // Açılış / Devir
}

/// UI tarafında listeleme yaparken kullanacağımız ORTAK model
class AccountTransactionModel {
  final String id; // İşlem ID'si (Benzersiz olması için String tutuyoruz)
  final DateTime date; // İşlem tarihi
  final String title; // Başlık (Örn: "Satış Fişi #123", "Nakit Tahsilat")
  final String? subtitle; // Alt başlık (Örn: "Açıklama: Elden alındı")
  final double amount; // Tutar
  final TransactionType type; // İşlem türü
  final String? status; // Durum (Ödendi, Kısmi, Bekliyor)

  AccountTransactionModel({
    required this.id,
    required this.date,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.type,
    this.status,
  });

  // --------------------------------------------------------------------------
  // YARDIMCI GETTERLAR (UI'da if-else yazmamak için)
  // --------------------------------------------------------------------------

  // İşlem bakiyeyi artırıyor mu? (Borçlanma)
  bool get isDebtIncrease =>
      type == TransactionType.sale || type == TransactionType.purchase;

  // Rengi ne olsun? (Borç artışı Kırmızı, Ödeme Yeşil)
  Color get amountColor => isDebtIncrease ? Colors.red : Colors.green;

  // Tutarın önüne + veya - koy
  String get amountPrefix => isDebtIncrease ? "-" : "+";

  // İkon ne olsun?
  IconData get icon {
    switch (type) {
      case TransactionType.sale:
        return Icons.shopping_cart_outlined;
      case TransactionType.purchase:
        return Icons.inventory_2_outlined;
      case TransactionType.collection:
        return Icons.arrow_downward; // Kasaya giriş
      case TransactionType.payment:
        return Icons.arrow_upward; // Kasadan çıkış
      default:
        return Icons.info_outline;
    }
  }
}
