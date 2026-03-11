import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/current_accounts/presentation/providers/account_provider.dart';
import 'package:mobile/features/current_accounts/presentation/screens/add_customer_screen.dart';
import 'package:mobile/features/current_accounts/presentation/widgets/account_list_item.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dialogs/transaction_master_dialog.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final overviewAsync = ref.watch(customerOverviewProvider);
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Müşteriler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          // Rapor / Yazdır aksiyonu için placeholder
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          "Yeni Müşteri",
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
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: _PrimaryAmountCard(
                                title: "Toplam Alacak",
                                amount: overview.totalReceivable,
                                icon: Icons.account_balance_wallet_outlined,
                                accentColor: AppColors.error,
                                subtitle:
                                    "Kliniğin tahsil etmesi gereken toplam tutar",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: customersAsync.when(
                                loading: () => const _SkeletonCard(),
                                error:
                                    (_, __) => _DebtorCustomersCard(
                                      totalCustomers: 0,
                                      debtorCount: 0,
                                      onTap: null,
                                    ),
                                data: (customers) {
                                  final total = overview.totalCustomers;
                                  final debtors =
                                      customers
                                          .where((c) => c.currentBalance > 0)
                                          .toList();
                                  return _DebtorCustomersCard(
                                    totalCustomers: total,
                                    debtorCount: debtors.length,
                                    onTap:
                                        debtors.isEmpty
                                            ? null
                                            : () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) =>
                                                        _DebtorCustomersDialog(
                                                          customers: debtors,
                                                        ),
                                              );
                                            },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _TodayCollectionCard(
                                total: overview.todayTotalCollection,
                                cash: overview.todayCash,
                                card: overview.todayCard,
                                currency: currency,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _PrimaryAmountCard(
                            title: "Toplam Alacak",
                            amount: overview.totalReceivable,
                            icon: Icons.account_balance_wallet_outlined,
                            accentColor: AppColors.error,
                            subtitle:
                                "Kliniğin tahsil etmesi gereken toplam tutar",
                          ),
                          const SizedBox(height: 12),
                          _TodayCollectionCard(
                            total: overview.todayTotalCollection,
                            cash: overview.todayCash,
                            card: overview.todayCard,
                            currency: currency,
                          ),
                          const SizedBox(height: 12),
                          customersAsync.when(
                            loading: () => const _SkeletonCard(),
                            error:
                                (_, __) => _DebtorCustomersCard(
                                  totalCustomers: 0,
                                  debtorCount: 0,
                                  onTap: null,
                                ),
                            data: (customers) {
                              final total = overview.totalCustomers;
                              final debtors =
                                  customers
                                      .where((c) => c.currentBalance > 0)
                                      .toList();
                              return _DebtorCustomersCard(
                                totalCustomers: total,
                                debtorCount: debtors.length,
                                onTap:
                                    debtors.isEmpty
                                        ? null
                                        : () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (_) => _DebtorCustomersDialog(
                                                  customers: debtors,
                                                ),
                                          );
                                        },
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
                  hintText: "Müşteri adı, telefon veya vergi no ara...",
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
            customersAsync.when(
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
              data: (customers) {
                final filtered =
                    customers
                        .where(
                          (c) =>
                              c.fullName.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              (c.phone ?? '').toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "Hiç müşteri bulunamadı.",
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
                    final c = filtered[index];
                    return AccountListItem(
                      title: c.fullName,
                      subtitle: c.phone ?? c.city ?? "Detay yok",
                      balance: c.currentBalance,
                      isSupplier: false,
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder:
                              (_) => TransactionMasterDialog(
                                viewType: TransactionViewType.customer,
                                customerId: c.id,
                                customerName: c.fullName,
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

class _DebtorCustomersCard extends StatelessWidget {
  final int totalCustomers;
  final int debtorCount;
  final VoidCallback? onTap;

  const _DebtorCustomersCard({
    required this.totalCustomers,
    required this.debtorCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = onTap != null && debtorCount > 0;

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
            "Borçlu Müşteriler",
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
                debtorCount.toString(),
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
                  Icons.people_alt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Toplam $totalCustomers müşteri kayıtlı",
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasAction
                    ? "Detayları görmek için tıklayın"
                    : "Borcu olan müşteri yok",
                style: TextStyle(
                  fontSize: 11,
                  color:
                      hasAction ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: hasAction ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (hasAction)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ],
      ),
    );

    if (!hasAction) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class _TodayCollectionCard extends StatelessWidget {
  final double total;
  final double cash;
  final double card;
  final NumberFormat currency;

  const _TodayCollectionCard({
    required this.total,
    required this.cash,
    required this.card,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_rounded, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text(
                "Bugünkü Toplam Tahsilat",
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
            currency.format(total),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Nakit:",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency.format(cash),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Kart:",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency.format(card),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _DebtorCustomersDialog extends StatelessWidget {
  final List<dynamic> customers;

  const _DebtorCustomersDialog({required this.customers});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.people_alt, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Borçlu Müşteriler Listesi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = customers[index];
                  return ListTile(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => TransactionMasterDialog(
                              viewType: TransactionViewType.customer,
                              customerId: c.id,
                              customerName: c.fullName,
                            ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        c.fullName.isNotEmpty
                            ? c.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      c.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.phone ?? c.city ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currency.format(c.currentBalance),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const Text(
                          "Detay için tıklayın",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
