import 'dart:io';
import 'package:flutter/foundation.dart'; // 👈 Bu paketi ekle (kIsWeb için)

class ApiConstants {
  static String get baseUrl {
    // 1. Önce Web kontrolü yapıyoruz (Çünkü Web'de Platform.isAndroid hata verir)
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // 2. Web değilse Mobil/Desktop kontrolü yapabiliriz
    else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api'; // iOS veya Desktop
    }
  }

  static String get baseUrlImage {
    return baseUrl.replaceAll('/api', '').replaceAll(RegExp(r'/$'), '');
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Additional auth endpoints
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String sessions = '/auth/sessions';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // User management endpoints (admin)
  static const String users = '/users';

  // Dashboard Endpoints
  static const String dashboardSummary = '/dashboard/summary';

  // Product Endpoints
  static const String products = '/products';

  // Barcode Endpoints
  static const String barcodeLookup = '/barcode/lookup';

  // Customer Endpoints
  static const String customers = '/customers';

  // Supplier Endpoints
  static const String suppliers = '/suppliers';

  // Sales Endpoints
  static const String sales = '/sales';

  // Finance / Cash register
  static const String financeExpenses = '/finance/expenses';
  static const String financeCollections = '/finance/collections';
  static const String financeCustomerDebtSummary =
      '/finance/customers'; // /:customerId/debt-summary
  static const String financeTransactionDetail =
      '/finance/transactions'; // /:transactionId

  // Endpoints
  static const String dashboardTurnoverDetails = '/dashboard/turnover-details';
  static const String dashboardInflationDetails =
      '/dashboard/inflation-details';
  static const String salesHistory = '/sales/history';

  // Timeout Süreleri (Opsiyonel ama iyi pratiktir)
  static const int connectTimeout = 5000; // 5 saniye
  static const int receiveTimeout = 5000;
}
