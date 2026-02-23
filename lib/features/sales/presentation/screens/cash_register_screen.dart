import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/cash_register_provider.dart';
import '../widgets/cash_register/add_expense_dialog.dart';
import '../widgets/cash_register/cash_date_header.dart';
import '../widgets/cash_register/cash_stats_grid.dart';
import '../widgets/cash_register/cash_transaction_list.dart';

class CashRegisterScreen extends ConsumerWidget {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashRegisterProvider);
    final notifier = ref.read(cashRegisterProvider.notifier);

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

            // 3. AKSİYON & FİLTRE BAR
            Row(
              children: [
                // Masraf Ekle Butonu
                ElevatedButton.icon(
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

                const SizedBox(width: 16),

                // Tahsilat Butonu (Navigasyon yapılabilir)
                ElevatedButton.icon(
                  onPressed: () {
                    // Müşteri listesine veya Tahsilat dialoguna yönlendir
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

                const Spacer(),

                // Filtre Segmentleri
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

            const SizedBox(height: 16),

            // 4. İŞLEM LİSTESİ
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
