import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_filter_provider.dart';
import '../../../../../core/theme/app_colors.dart';

class TransactionAdvancedFilterDialog extends ConsumerWidget {
  const TransactionAdvancedFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Gelişmiş Filtreleme",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: notifier.clearFilters,
                  child: const Text(
                    "Temizle",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Saat Aralıkları (Checkbox Group)
            const Text(
              "Saat Aralığı",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTimeCheckbox("08:00 - 12:00", "08-12", state, notifier),
                _buildTimeCheckbox("12:00 - 15:00", "12-15", state, notifier),
                _buildTimeCheckbox("15:00 - 18:00", "15-18", state, notifier),
                _buildTimeCheckbox("18:00 - 22:00", "18-22", state, notifier),
                _buildTimeCheckbox("Gece (22+)", "22-24", state, notifier),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Tutar Filtresi (Radio + Inputs)
            const Text(
              "Tutar Filtresi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRadio("Toplam", "TOTAL", state, notifier),
                _buildRadio("Ödenen", "PAID", state, notifier),
                _buildRadio("Borç", "DEBT", state, notifier),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.minAmount?.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.setMinAmount,
                    decoration: const InputDecoration(
                      labelText: "Min Tutar (₺)",
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: state.maxAmount?.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.setMaxAmount,
                    decoration: const InputDecoration(
                      labelText: "Max Tutar (₺)",
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Özel Durumlar (Switch/Checkbox)
            const Text(
              "Özel Durumlar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SwitchListTile(
              title: const Text(
                "Sadece Zam Farkı Olanlar",
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                "Enflasyondan etkilenen borçlu satışlar",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: state.onlyInflation,
              onChanged: notifier.toggleInflation,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text(
                "Not Girilmiş İşlemler",
                style: TextStyle(fontSize: 14),
              ),
              value: state.onlyWithNote,
              onChanged: notifier.toggleWithNote,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Sonuçları Göster"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCheckbox(
    String label,
    String value,
    TransactionFilterState state,
    TransactionFilterNotifier notifier,
  ) {
    final isSelected = state.selectedTimeRanges.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.toggleTimeRange(value),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildRadio(
    String label,
    String value,
    TransactionFilterState state,
    TransactionFilterNotifier notifier,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: state.amountFilterType,
          onChanged: (val) => notifier.setAmountFilterType(val!),
          activeColor: AppColors.primary,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
      ],
    );
  }
}
