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

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Dashboard Endpoints
  static const String dashboardSummary = '/dashboard/summary';

  // Product Endpoints
  static const String products = '/products';

  // Customer Endpoints
  static const String customers = '/customers';

  // Supplier Endpoints
  static const String suppliers = '/suppliers';

  // Sales Endpoints
  static const String sales = '/sales';

  // Endpoints
  static const String dashboardTurnoverDetails = '/dashboard/turnover-details';
  static const String dashboardInflationDetails =
      '/dashboard/inflation-details';
  static const String salesHistory = '/sales/history';

  // Timeout Süreleri (Opsiyonel ama iyi pratiktir)
  static const int connectTimeout = 5000; // 5 saniye
  static const int receiveTimeout = 5000;
}
