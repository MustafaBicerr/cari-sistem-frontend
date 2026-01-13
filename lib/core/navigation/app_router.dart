import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/products/presentation/screens/product_list_screen.dart';
import 'package:mobile/shared/layouts/main_layout.dart';

// Auth Screens
import '../../features/auth/presentation/screens/login_screen.dart';

// Clinic Screens
import '../../features/clinic/presentation/screens/clinic_menu_screen.dart';
import '../../features/clinic/presentation/screens/patient_list_screen.dart';
import '../../features/clinic/presentation/screens/appointment_screen.dart';

// Sales Screens
import '../../features/sales/presentation/screens/quick_sale_screen.dart';
import '../../features/sales/presentation/screens/cash_register_screen.dart';

// Stock Screens
import '../../features/stock/presentation/screens/stock_menu_screen.dart';
import '../../features/stock/presentation/screens/stock_entry_screen.dart';

// Accounts Screens
import '../../features/accounts/presentation/screens/customer_list_screen.dart';
import '../../features/accounts/presentation/screens/supplier_list_screen.dart';

// Settings Screen
import '../../features/settings/presentation/screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login', // Başlangıç rotası
    routes: [
      // Login (Shell dışında, tam ekran)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Shell (Menülü Yapı)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          // 1. DASHBOARD
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),

          // 2. KLİNİK
          GoRoute(
            path: '/clinic',
            builder: (context, state) => const ClinicMenuScreen(),
            routes: [
              GoRoute(
                path: 'patients',
                builder: (context, state) => const PatientListScreen(),
              ),
              GoRoute(
                path: 'appointments',
                builder: (context, state) => const AppointmentScreen(),
              ),
            ],
          ),

          // 3. SATIŞ (Sales) - 🔥 DÜZELTİLDİ
          GoRoute(
            path: '/sales',
            // Eğer /sales'e tıklanırsa varsayılan olarak POS ekranına git.
            redirect: (context, state) {
              if (state.uri.toString() == '/sales') {
                return '/sales/pos';
              }
              return null;
            },
            routes: [
              GoRoute(
                path: 'pos',
                builder: (context, state) => const QuickSaleScreen(),
              ),
              GoRoute(
                path: 'cash',
                builder: (context, state) => const CashRegisterScreen(),
              ),
            ],
          ),

          // 4. STOK (Stock) - 🔥 DÜZELTİLDİ
          GoRoute(
            path: '/stock',
            // Stok ana sayfasına tıklayınca Menü sayfasını gösteriyoruz.
            builder: (context, state) => const StockMenuScreen(),
            routes: [
              GoRoute(
                path: 'entry',
                builder: (context, state) => const StockEntryScreen(),
              ),
              // Çift olan 'products' rotasını temizledim, tek bıraktım:
              GoRoute(
                path: 'products',
                builder: (context, state) => const ProductListScreen(),
              ),
            ],
          ),

          // 5. CARİ (Accounts) - 🔥 DÜZELTİLDİ
          GoRoute(
            path: '/accounts',
            // Eğer /accounts'a tıklanırsa varsayılan olarak Müşterilere git.
            redirect: (context, state) {
              if (state.uri.toString() == '/accounts') {
                return '/accounts/customers';
              }
              return null;
            },
            routes: [
              GoRoute(
                path: 'customers',
                builder: (context, state) => const CustomerListScreen(),
              ),
              GoRoute(
                path: 'suppliers',
                builder: (context, state) => const SupplierListScreen(),
              ),
            ],
          ),

          // 6. AYARLAR
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
