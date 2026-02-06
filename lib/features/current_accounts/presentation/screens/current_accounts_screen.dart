import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/current_accounts/presentation/widgets/customer_detail_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/account_provider.dart';
import '../widgets/account_list_item.dart';
import 'add_customer_screen.dart';
import 'add_supplier_screen.dart';

class CurrentAccountsScreen extends ConsumerStatefulWidget {
  const CurrentAccountsScreen({super.key});

  @override
  ConsumerState<CurrentAccountsScreen> createState() =>
      _CurrentAccountsScreenState();
}

class _CurrentAccountsScreenState extends ConsumerState<CurrentAccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verileri çek
    final customersAsync = ref.watch(customerListProvider);
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Cari Hesaplar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: "Müşteriler"), Tab(text: "Tedarikçiler")],
        ),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Ara...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. MÜŞTERİLER
                customersAsync.when(
                  data: (list) {
                    final filtered =
                        list
                            .where(
                              (c) => c.fullName.toLowerCase().contains(
                                _searchQuery,
                              ),
                            )
                            .toList();
                    if (filtered.isEmpty)
                      return const _EmptyState(message: "Müşteri bulunamadı");

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder:
                          (ctx, i) => AccountListItem(
                            title: filtered[i].fullName,
                            subtitle:
                                filtered[i].phone ??
                                filtered[i].city ??
                                "Detay yok",
                            balance: filtered[i].currentBalance,
                            isSupplier: false,
                            onTap: () {
                              // TODO: Detay sayfasına git (Sonraki adım)
                              showDialog(
                                context: context,
                                barrierDismissible:
                                    true, // Boşluğa basınca kapansın
                                builder:
                                    (context) => CustomerDetailDialog(
                                      customerId: filtered[i].id,
                                    ),
                              );
                            },
                          ),
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Hata: $e")),
                ),

                // 2. TEDARİKÇİLER
                suppliersAsync.when(
                  data: (list) {
                    final filtered =
                        list
                            .where(
                              (s) =>
                                  s.name.toLowerCase().contains(_searchQuery),
                            )
                            .toList();
                    if (filtered.isEmpty)
                      return const _EmptyState(message: "Tedarikçi bulunamadı");

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder:
                          (ctx, i) => AccountListItem(
                            title: filtered[i].name,
                            subtitle:
                                filtered[i].contactPerson ??
                                filtered[i].phone ??
                                "Detay yok",
                            balance: filtered[i].currentBalance,
                            isSupplier: true,
                            onTap: () {
                              // TODO: Detay sayfasına git (Sonraki adım)
                              context.push(
                                '/supplier-detail/${filtered[i].id}',
                              );
                            },
                          ),
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Hata: $e")),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
            );
          }
        },
        label: Text(
          _tabController.index == 0 ? "Müşteri Ekle" : "Tedarikçi Ekle",
        ),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
