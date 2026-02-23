import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../providers/cash_register_provider.dart';

class CashDateHeader extends ConsumerWidget {
  const CashDateHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashRegisterProvider);
    final notifier = ref.read(cashRegisterProvider.notifier);
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // TARİH SEÇİCİ
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: state.selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('tr', 'TR'),
            );
            if (date != null) notifier.changeDate(date);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  dateFormat.format(state.selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),

        // GÜN SONU RAPORU BUTONU
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Print / Export Logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gün sonu raporu yazdırılıyor...")),
            );
          },
          icon: const Icon(Icons.print, color: Colors.white, size: 18),
          label: const Text(
            "GÜN SONU",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
