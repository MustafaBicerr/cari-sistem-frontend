class ApiConstants {
  static String get baseUrl {
    // Tek kaynaklı yönetim için:
    // - Development: LOCAL_API_BASE (localhost / emulator)
    // - Production: PROD_API_BASE (sunucu IP / domain)
    //
    // Bu dosya git'e commit edilir; gerçek değerler .env ve
    // --dart-define ile yönetilir.
    const String devBase = String.fromEnvironment(
      'MOBILE_API_BASE_DEV',
      defaultValue: 'http://localhost:3000/api',
    );
    const String androidBase = String.fromEnvironment(
      'MOBILE_API_BASE_ANDROID',
      defaultValue: 'http://10.0.2.2:3000/api',
    );
    const String prodBase = String.fromEnvironment(
      'MOBILE_API_BASE_PROD',
      defaultValue: 'https://api.vetapp.com.tr/api',
    );

    // Basit strateji:
    // - Debug build'lerde dev/android değerleri
    // - Release build'lerde prod değeri
    // (Detaylı ortam yönetimi için ayrı flavor'lar eklenebilir.)
    assert(() {
      // Debug modda: Android emulator için özel hostname kullan
      // (Gerekirse platform kontrolü ileride eklenebilir)
      return true;
    }());

    const bool isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      return prodBase;
    }
    // Debug / profile:
    // Android emulator kullanılıyorsa derleme tarafında
    // MOBILE_API_BASE_ANDROID ile override edilebilir.
    return androidBase.isNotEmpty ? androidBase : devBase;
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
