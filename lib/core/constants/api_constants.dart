class ApiConstants {
  // Base URL (Tek yerden değiştir, her yer değişsin!)
  // Android Emülatör: 'http://10.0.2.2:3000/api'
  // iOS / Web: 'http://localhost:3000/api'
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Dashboard Endpoints
  static const String dashboardSummary = '/dashboard/summary';

  // Product Endpoints
  static const String products = '/products';

  // Customer Endpoints
  static const String customers = '/customers';

  // Timeout Süreleri (Opsiyonel ama iyi pratiktir)
  static const int connectTimeout = 5000; // 5 saniye
  static const int receiveTimeout = 5000;
}
