import 'package:flutter/material.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/products/presentation/screens/product_list_screen.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/app_colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Sayfalarımız (Şimdilik Placeholder)
  final List<Widget> _screens = [
    const Center(child: DashboardScreen()),
    const Center(child: ProductListScreen()),
    const Center(child: Text("👥 Müşteriler & Hastalar")),
    const Center(child: Text("💰 Satış & Kasa")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      // MOBİL GÖRÜNÜM: Altta Menü
      mobile: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Özet',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Ürünler',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Müşteriler',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale),
              label: 'Satış',
            ),
          ],
        ),
      ),

      // DESKTOP GÖRÜNÜM: Solda Sidebar
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              extended: true, // Yazıları göster (Geniş Sidebar)
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: Text('Özet Durum'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Ürün Yönetimi'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  label: Text('Müşteriler'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale),
                  label: Text('Satış Ekranı'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1), // İnce çizgi
            Expanded(
              child: Container(
                color: AppColors.background, // Gri arka plan
                child: _screens[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
