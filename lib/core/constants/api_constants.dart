import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    // Ortak yapı:
    // - Development:
    //   * Web & Desktop: localhost (MOBILE_API_BASE_DEV)
    //   * Android emulator: 10.0.2.2 (MOBILE_API_BASE_ANDROID)
    //   * iOS simulator / diğerleri: localhost (MOBILE_API_BASE_DEV)
    // - Production (release build): MOBILE_API_BASE_PROD
    //
    // Gerçek değerler sunucudaki .env dosyasından gelir ve
    // build sırasında --dart-define ile aktarılır.
    const devBase = String.fromEnvironment(
      'MOBILE_API_BASE_DEV',
      defaultValue: 'http://localhost:3000/api',
    );
    const androidBase = String.fromEnvironment(
      'MOBILE_API_BASE_ANDROID',
      defaultValue: 'http://10.0.2.2:3000/api',
    );
    const prodBase = String.fromEnvironment(
      'MOBILE_API_BASE_PROD',
      defaultValue: 'https://api.vetapp.com.tr/api',
    );

    const isRelease = bool.fromEnvironment('dart.vm.product');

    // 1) Production: her platformda doğrudan PROD URL
    if (isRelease) {
      return prodBase;
    }

    // 2) Development / profile:
    // Platforma göre doğru host'u seç.

    // Web & desktop: backend aynı makinede, doğrudan localhost kullan.
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return devBase;
    }

    // Android emulator: host makineye 10.0.2.2 üzerinden gider.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidBase;
    }

    // iOS simulator veya diğer platformlar: varsayılan olarak localhost.
    return devBase;
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
