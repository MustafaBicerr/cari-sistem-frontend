import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/dashboard/presentation/widgets/stat_card.dart';
import '../../providers/cash_register_provider.dart';

class CashStatsGrid extends ConsumerWidget {
  const CashStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashRegisterProvider);

    // Responsive Grid Hesabı
    return LayoutBuilder(
      builder: (context, constraints) {
        // Geniş ekranda 4, mobilde 2 sütun
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        final childAspectRatio = constraints.maxWidth > 900 ? 1.5 : 1.0;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            // 1. NAKİT KASA
            StatCard(
              title: "Nakit Kasa",
              value: "₺${state.dailyCashBalance.toStringAsFixed(2)}",
              icon: Icons.payments,
              color: AppColors.success,
              // trend: "Nakit Akışı",
              // isPositive: true,
            ),
            // 2. POS / KART
            StatCard(
              title: "POS / Kredi Kartı",
              value: "₺${state.dailyCardBalance.toStringAsFixed(2)}",
              icon: Icons.credit_card,
              color: AppColors.primary,
              // trend: "Banka Hesabı",
              // isPositive: true,
            ),
            // 3. GİDERLER
            StatCard(
              title: "Günlük Gider",
              value: "₺${state.dailyExpense.toStringAsFixed(2)}",
              icon: Icons.trending_down,
              color: AppColors.error,
              // trend: "Toplam Harcama",
              // isPositive: false,
            ),
            // 4. NET KASA (Nakit + Kart - Gider)
            StatCard(
              title: "Net Kasa",
              value:
                  "₺${(state.dailyCashBalance + state.dailyCardBalance - state.dailyExpense).toStringAsFixed(2)}",
              icon: Icons.account_balance_wallet,
              color: Colors.blueGrey,
              // trend: "Toplam Varlık",
              // isPositive: true,
            ),
          ],
        );
      },
    );
  }
}
