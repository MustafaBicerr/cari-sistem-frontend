import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/current_accounts/presentation/screens/current_accounts_screen.dart';
import 'package:mobile/features/current_accounts/presentation/screens/customer_detail_screen.dart';
import 'package:mobile/features/current_accounts/presentation/screens/supplier_detail_screen.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/products/presentation/screens/product_list_screen.dart';
import 'package:mobile/shared/layouts/main_layout.dart';

// Auth Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';

// Clinic Screens
import '../../features/clinic/presentation/screens/clinic_menu_screen.dart';
import '../../features/clinic/presentation/screens/patient_list_screen.dart';
import '../../features/clinic/presentation/screens/appointment_screen.dart';

// Sales Screens
import '../../features/sales/presentation/screens/quick_sale_screen.dart';
import '../../features/sales/presentation/screens/cash_register_screen.dart';

// Stock Screens
import '../../features/stock/presentation/screens/stock_entry_screen.dart';

// Accounts Screens
import '../../features/accounts/presentation/screens/customer_list_screen.dart';

// Settings Screen
import '../../settings/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

// Auth state listenable for GoRouter to rebuild on auth changes
class _AuthStateListenable extends ValueNotifier<bool> {
  final Ref ref;

  _AuthStateListenable(this.ref) : super(false) {
    _init();
  }

  void _init() {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      // Notify GoRouter to rebuild when auth state changes
      notifyListeners();
    });
  }
}

// Riverpod provider for the router
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authStateListenable = _AuthStateListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authStateListenable,
    redirect: (context, state) {
      final location = state.uri.path;

      // While auth state is loading or unknown, don't redirect
      if (authState.status == AuthStatus.unknown ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      // If user is unauthenticated
      if (authState.status == AuthStatus.unauthenticated) {
        // Allow access to login and register
        if (location == '/login' || location == '/register') {
          return null;
        }
        // Redirect all other routes to login
        return '/login';
      }

      // If user must change password
      if (authState.status == AuthStatus.mustChangePassword) {
        if (location == '/auth/reset-password') {
          return null;
        }
        return '/auth/reset-password';
      }

      // If user is authenticated
      if (authState.status == AuthStatus.authenticated) {
        // Prevent access to login/register, redirect to home
        if (location == '/login' || location == '/register') {
          return '/';
        }
        // Allow access to all authenticated routes
        return null;
      }

      return null;
    },
    routes: [
      // Auth Routes (outside Shell)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Shell (Main Layout with Navigation)
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
            builder: (context, state) => const StockEntryScreen(),
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
                builder: (context, state) => const CurrentAccountsScreen(),
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

      // 👇 YENİ EKLENECEK ROTALAR 👇

      // 1. Tedarikçi Detay Rotası
      // :id kısmı dinamik parametredir.
      GoRoute(
        path: '/supplier-detail/:id',
        builder: (context, state) {
          // URL'den ID'yi alıyoruz (String olarak gelir, int'e çeviriyoruz)
          final id = state.pathParameters['id']!;
          return SupplierDetailScreen(supplierId: id);
        },
      ),

      // 2. Müşteri Detay Rotası
      GoRoute(
        path: '/customer-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
    ],
  );
}); // Close the appRouterProvider
