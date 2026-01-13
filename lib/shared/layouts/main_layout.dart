import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/app_colors.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  // Menü Yapısı Tanımları
  final List<_NavItem> _navItems = const [
    _NavItem(title: 'Özet', icon: Icons.dashboard_outlined, route: '/'),
    _NavItem(
      title: 'Klinik',
      icon: Icons.medical_services_outlined,
      children: [
        _NavItem(title: 'Genel Bakış', route: '/clinic'),
        _NavItem(title: 'Hasta Listesi', route: '/clinic/patients'),
        _NavItem(title: 'Randevular', route: '/clinic/appointments'),
      ],
    ),
    _NavItem(
      title: 'Satış',
      icon: Icons.point_of_sale,
      children: [
        _NavItem(title: 'Hızlı Satış (POS)', route: '/sales/pos'),
        _NavItem(title: 'Kasa İşlemleri', route: '/sales/cash'),
      ],
    ),
    _NavItem(
      title: 'Stok',
      icon: Icons.inventory_2_outlined,
      children: [
        _NavItem(title: 'Stok Durumu', route: '/stock'),
        _NavItem(title: 'Ürünler', route: '/stock/products'),
        _NavItem(title: 'Stok Girişi', route: '/stock/entry'),
      ],
    ),
    _NavItem(
      title: 'Cari',
      icon: Icons.people_alt_outlined,
      children: [
        _NavItem(title: 'Müşteriler', route: '/accounts/customers'),
        _NavItem(title: 'Tedarikçiler', route: '/accounts/suppliers'),
      ],
    ),
  ];

  // Mevcut rotaya göre index'i hesapla
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/clinic')) return 1;
    if (location.startsWith('/sales')) return 2;
    if (location.startsWith('/stock')) return 3;
    if (location.startsWith('/accounts')) return 4;
    if (location.startsWith('/settings')) return 5; // Ayarlar için özel durum
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/clinic');
        break;
      case 2:
        context.go('/sales');
        break;
      case 3:
        context.go('/stock');
        break;
      case 4:
        context.go('/accounts');
        break;
      // Ayarlar butonu ayrı yönetildiği için buraya case eklemedim,
      // ama NavigationBar'da index 5 gelirse diye eklenebilir.
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);
    final String currentLocation = GoRouterState.of(context).uri.toString();

    return ResponsiveLayout(
      // MOBİL GÖRÜNÜM: Altta Menü
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('Cari Sistem'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
            ),
          ],
        ),
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex:
              selectedIndex > 4
                  ? 0
                  : selectedIndex, // Ayarlar seçiliyse dashboard gibi davranmasın
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Özet',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              label: 'Klinik',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale),
              label: 'Satış',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Stok',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              label: 'Cari',
            ),
          ],
        ),
      ),

      // DESKTOP GÖRÜNÜM: Solda Sidebar
      desktop: Scaffold(
        body: Row(
          children: [
            _buildSidebar(context, currentLocation),
            const VerticalDivider(thickness: 1, width: 1), // İnce çizgi
            Expanded(
              child: Container(
                color: AppColors.background, // Gri arka plan
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DESKTOP SIDEBAR WIDGETS ---

  Widget _buildSidebar(BuildContext context, String currentLocation) {
    return Container(
      width: 260, // Sidebar genişliği
      color: Colors.white,
      child: Column(
        children: [
          // Logo / Başlık Alanı
          Container(
            height: 64,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Row(
              children: [
                Icon(Icons.inventory, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Cari Sistem',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Menü Listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children:
                  _navItems.map((item) {
                    return _buildSidebarItem(context, item, currentLocation);
                  }).toList(),
            ),
          ),

          // Alt Kısım (Ayarlar)
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text(
              'Ayarlar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            onTap: () => context.go('/settings'),
            selected: currentLocation.startsWith('/settings'),
            selectedColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    _NavItem item,
    String currentLocation,
  ) {
    // Eğer alt elemanları varsa ExpansionTile kullan
    if (item.children.isNotEmpty) {
      // Bu grubun açık olup olmadığını kontrol et (Aktif sayfa bu grubun içindeyse)
      final bool isActive = item.children.any(
        (child) =>
            child.route != null && currentLocation.startsWith(child.route!),
      );

      return ExpansionTile(
        key: PageStorageKey<String>(item.title), // Durumu korumak için
        initiallyExpanded: isActive,
        leading: Icon(
          item.icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 12), // Girinti
        children:
            item.children
                .map(
                  (child) => _buildSidebarItem(context, child, currentLocation),
                )
                .toList(),
      );
    }

    final bool isParentSelected =
        item.route != null && currentLocation == item.route;

    // Tekil Eleman (Yaprak)
    final bool isSelected = item.route != null && currentLocation == item.route;

    return ListTile(
      leading: Icon(
        // Alt elemanlar için nokta ikonu, ana elemanlar için kendi ikonu
        item.icon == Icons.circle_outlined ? Icons.circle : item.icon,
        size: item.icon == Icons.circle_outlined ? 10 : 24,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        if (item.route != null) context.go(item.route!);
      },
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
    );
  }
}

// Yardımcı Model Sınıfı
class _NavItem {
  final String title;
  final IconData icon;
  final String? route;
  final List<_NavItem> children;

  const _NavItem({
    required this.title,
    this.icon = Icons.circle_outlined, // Varsayılan alt ikon
    this.route,
    this.children = const [],
  });
}
