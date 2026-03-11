import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/cash_register_provider.dart';
import '../widgets/cash_register/add_expense_dialog.dart';
import '../widgets/cash_register/cash_date_header.dart';
import '../widgets/cash_register/cash_stats_grid.dart';
import '../widgets/cash_register/cash_transaction_list.dart';
import '../widgets/cash_register/collection_dialog.dart';

class CashRegisterScreen extends ConsumerWidget {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashRegisterProvider);
    final notifier = ref.read(cashRegisterProvider.notifier);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Kasa & Gider Yönetimi"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => notifier.loadDailyData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÜST PANEL (Tarih & Rapor)
            const CashDateHeader(),

            const SizedBox(height: 24),

            // 2. İSTATİSTİK KARTLARI
            const CashStatsGrid(),

            const SizedBox(height: 32),

            // 3. AKSİYON BUTONLARI
            Row(
              children: [
                // Masraf Ekle Butonu
                Expanded(
                  flex: isMobile ? 1 : 0,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddExpenseDialog(),
                      );
                    },
                    icon: const Icon(Icons.remove_circle, color: Colors.white),
                    label: const Text(
                      "MASRAF GİR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Tahsilat Butonu
                Expanded(
                  flex: isMobile ? 1 : 0,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CollectionDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text(
                      "TAHSİLAT YAP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (!isMobile) const Spacer(),

                if (!isMobile) ...[
                  // Desktop/Web: Filtreler aynı satırda kalsın
                  _buildFilterChip("Tümü", 'ALL', state.filterType, notifier),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Gelirler",
                    'INCOME',
                    state.filterType,
                    notifier,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Giderler",
                    'EXPENSE',
                    state.filterType,
                    notifier,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Mobilde Filtre Segmentleri: Arama çubuğunun hemen üstünde
            if (isMobile) ...[
              Row(
                children: [
                  _buildFilterChip("Tümü", 'ALL', state.filterType, notifier),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Gelirler",
                    'INCOME',
                    state.filterType,
                    notifier,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "Giderler",
                    'EXPENSE',
                    state.filterType,
                    notifier,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 4. MÜŞTERİ ARAMA (Liste filtresi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => notifier.setCustomerSearchQuery(v),
                decoration: InputDecoration(
                  hintText: "Müşteri adına göre filtrele...",
                  prefixIcon: const Icon(Icons.person_search, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 5. İŞLEM LİSTESİ
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const CashTransactionList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentFilter,
    CashRegisterNotifier notifier,
  ) {
    final isSelected = value == currentFilter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.setFilter(value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}
