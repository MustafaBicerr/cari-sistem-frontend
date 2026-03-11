import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/current_accounts/presentation/providers/account_provider.dart';
import 'package:mobile/features/current_accounts/presentation/screens/add_supplier_screen.dart';
import 'package:mobile/features/current_accounts/presentation/widgets/account_list_item.dart';
import 'package:mobile/features/current_accounts/presentation/screens/supplier_detail_screen.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dialogs/supplier_debt_dialog.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);
    final overviewAsync = ref.watch(supplierOverviewProvider);
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Tedarikçiler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.domain_add, color: Colors.white),
        label: const Text(
          "Yeni Tedarikçi",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: overviewAsync.when(
                loading:
                    () => const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (e, _) => SizedBox(
                      height: 90,
                      child: Center(
                        child: Text(
                          "Özet yüklenemedi",
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ),
                    ),
                data: (overview) {
                  final nearestDue = overview.nearestDueDate;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: _PrimaryAmountCard(
                                title: "Toplam Ödenecek Borç",
                                amount: overview.totalSupplierDebt,
                                icon: Icons.money_off_csred_outlined,
                                accentColor: AppColors.error,
                                subtitle:
                                    "Tedarikçilere ödenmesi gereken toplam tutar",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SupplierCountCard(
                                supplierCount: overview.supplierCount,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const SupplierDebtDialog(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _NearestDueCard(
                                nearestDueDate: nearestDue,
                                openInvoiceCount: overview.openInvoiceCount,
                                currency: currency,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const SupplierDebtDialog(),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _PrimaryAmountCard(
                            title: "Toplam Ödenecek Borç",
                            amount: overview.totalSupplierDebt,
                            icon: Icons.money_off_csred_outlined,
                            accentColor: AppColors.error,
                            subtitle:
                                "Tedarikçilere ödenmesi gereken toplam tutar",
                          ),
                          const SizedBox(height: 12),
                          _SupplierCountCard(
                            supplierCount: overview.supplierCount,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SupplierDebtDialog(),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _NearestDueCard(
                            nearestDueDate: nearestDue,
                            openInvoiceCount: overview.openInvoiceCount,
                            currency: currency,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SupplierDebtDialog(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Depo veya firma adı ara...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            suppliersAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text("Hata: $e")),
                  ),
              data: (suppliers) {
                final filtered =
                    suppliers
                        .where(
                          (s) =>
                              s.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              (s.contactPerson ?? '').toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "Tedarikçi bulunamadı.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return AccountListItem(
                      title: s.name,
                      subtitle:
                          s.contactPerson ??
                          s.phone ??
                          (s.city != null ? s.city! : "Detay yok"),
                      balance: s.currentBalance,
                      isSupplier: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SupplierDetailScreen(supplierId: s.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAmountCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color accentColor;
  final String subtitle;

  const _PrimaryAmountCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accentColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currency.format(amount),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCountCard extends StatelessWidget {
  final int supplierCount;
  final VoidCallback onTap;

  const _SupplierCountCard({required this.supplierCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Borcu Olan Tedarikçi",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                supplierCount.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Detayları görmek için tıklayın",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class _NearestDueCard extends StatelessWidget {
  final DateTime? nearestDueDate;
  final int openInvoiceCount;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _NearestDueCard({
    required this.nearestDueDate,
    required this.openInvoiceCount,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText =
        nearestDueDate != null
            ? DateFormat('dd.MM.yyyy').format(nearestDueDate!)
            : 'Tanımlı vade yok';

    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.event_available, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "En Yakın Ödeme",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$openInvoiceCount açık fatura",
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "En yakın vadeli borçları listele",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}
