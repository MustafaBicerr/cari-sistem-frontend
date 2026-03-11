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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final crossAxisCount = isDesktop ? 4 : 1;

        // Masaüstünde kareye yakın; mobilde yatay, alçak kartlar
        final childAspectRatio = isDesktop ? 1.5 : 3.8;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            // 1. NAKİT KASA
            _buildStatCard(
              isDesktop: isDesktop,
              title: "Nakit Kasa",
              value: "₺${state.dailyCashBalance.toStringAsFixed(2)}",
              icon: Icons.payments,
              color: AppColors.success,
            ),
            // 2. POS / KART
            _buildStatCard(
              isDesktop: isDesktop,
              title: "POS / Kredi Kartı",
              value: "₺${state.dailyCardBalance.toStringAsFixed(2)}",
              icon: Icons.credit_card,
              color: AppColors.primary,
            ),
            // 3. GİDERLER
            _buildStatCard(
              isDesktop: isDesktop,
              title: "Günlük Gider",
              value: "₺${state.dailyExpense.toStringAsFixed(2)}",
              icon: Icons.trending_down,
              color: AppColors.error,
            ),
            // 4. NET KASA (Nakit + Kart - Gider)
            _buildStatCard(
              isDesktop: isDesktop,
              title: "Net Kasa",
              value:
                  "₺${(state.dailyCashBalance + state.dailyCardBalance - state.dailyExpense).toStringAsFixed(2)}",
              icon: Icons.account_balance_wallet,
              color: Colors.blueGrey,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required bool isDesktop,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    if (isDesktop) {
      return StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      );
    }

    // Mobil görünüm: label solda, değer kartın en sağında
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
