import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../data/models/supplier_model.dart';
import '../providers/account_detail_provider.dart';
import '../providers/finance_provider.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dialogs/purchase_invoice_detail_dialog.dart';
import 'package:mobile/features/dashboard/presentation/screens/purchase_invoice_detail_screen.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  final Set<String> _selectedInvoiceIds = {};

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(supplierDetailProvider(widget.supplierId));
    final financeState = ref.watch(financeProvider);

    void showSnack(String message, {bool error = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : Colors.green,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Tedarikçi Detayı")),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Hata: $e")),
        data: (response) {
          final profile = response.profile;
          final history = response.history;
          final stats = response.stats;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildSummaryCard(profile, stats),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildContactCard(profile),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Faturalar",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildInvoiceList(history),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedInvoiceIds.isEmpty
                            ? "Seçili fatura yok"
                            : "${_selectedInvoiceIds.length} fatura seçildi",
                        style: const TextStyle(fontSize: 12),
                      ),
                      ElevatedButton.icon(
                        onPressed: financeState.isLoading ||
                                _selectedInvoiceIds.isEmpty
                            ? null
                            : () async {
                                final selectedInvoices = history
                                    .where(
                                      (h) =>
                                          _selectedInvoiceIds.contains(h.id),
                                    )
                                    .toList();
                                final totalRemaining = selectedInvoices.fold<
                                    double>(
                                  0,
                                  (sum, h) => sum + h.remainingAmount,
                                );

                                final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) {
                                        final currency =
                                            NumberFormat.currency(
                                          locale: 'tr_TR',
                                          symbol: '₺',
                                        );
                                        return AlertDialog(
                                          title: const Text("Hesabı Kapat"),
                                          content: Text(
                                            "Seçili ${selectedInvoices.length} fatura için toplam ${currency.format(totalRemaining)} tutarındaki borcu kapatmak istediğinize emin misiniz?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text("Vazgeç"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text("Onayla"),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false;

                                if (!confirm) return;

                                try {
                                  await ref
                                      .read(financeProvider.notifier)
                                      .paySupplierInvoices(
                                        supplierId: widget.supplierId,
                                        invoiceIds:
                                            _selectedInvoiceIds.toList(),
                                        paymentMethod: 'CASH',
                                      );
                                  _selectedInvoiceIds.clear();
                                  if (mounted) {
                                    showSnack(
                                      "Seçili faturalar için borç kapatıldı.",
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    showSnack(
                                      "Ödeme başarısız: $e",
                                      error: true,
                                    );
                                  }
                                }
                              },
                        icon: financeState.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: const Text("Hesabı Kapat"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(SupplierModel profile, SupplierStats? stats) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final balanceColor = profile.currentBalance > 0 ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Text(
              profile.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Güncel Borç",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                currency.format(profile.currentBalance),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats != null)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  label: "Toplam Sipariş",
                  value: "${stats.totalInvoices}",
                ),
                _buildStatChip(
                  label: "Toplam Hacim",
                  value: currency.format(stats.totalPurchaseVolume),
                ),
                _buildStatChip(
                  label: "Toplam Ürün Adedi",
                  value: stats.totalItems.toStringAsFixed(0),
                ),
                _buildStatChip(
                  label: "Ürün Çeşidi",
                  value: "${stats.productCount}",
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(SupplierModel profile) {
    Widget buildRow(IconData icon, String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String cityDistrict = [
      profile.city,
      profile.district,
    ].where((e) => e != null && e.isNotEmpty).join(' / ');

    String taxInfo = [
      profile.taxNumber,
      profile.taxOffice,
    ].where((e) => e != null && e.isNotEmpty).join(' / ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İletişim & Bilgiler",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          buildRow(Icons.person, "Sorumlu Kişi", profile.contactPerson),
          buildRow(Icons.phone, "Telefon", profile.phone),
          buildRow(Icons.email_outlined, "E-posta", profile.email),
          buildRow(Icons.location_on_outlined, "Adres", profile.address),
          buildRow(Icons.location_city, "Şehir / İlçe", cityDistrict),
          buildRow(Icons.account_balance, "IBAN", profile.iban),
          buildRow(Icons.badge, "Vergi No / Dairesi", taxInfo),
        ],
      ),
    );
  }

  Widget _buildStatChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(List<SupplierHistoryItem> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text("Henüz fatura kaydı yok."),
      );
    }

    final dateFmt = DateFormat('dd.MM.yyyy');
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = history[index];
        final isPaid = item.status == 'PAID';
        final isSelectable = !isPaid && item.remainingAmount > 0;
        final isSelected = _selectedInvoiceIds.contains(item.id);

        final bgColor = isPaid
            ? Colors.green.withOpacity(0.06)
            : Colors.red.withOpacity(0.04);
        final borderColor = isPaid ? Colors.green : Colors.redAccent;

        DateTime? invoiceDate;
        DateTime? dueDate;
        if (item.date.isNotEmpty) {
          invoiceDate = DateTime.tryParse(item.date);
        }
        if (item.dueDate.isNotEmpty) {
          dueDate = DateTime.tryParse(item.dueDate);
        }

        return InkWell(
          onTap: () {
            final isMobile = MediaQuery.of(context).size.width < 600;
            if (isMobile) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PurchaseInvoiceDetailScreen(invoiceId: item.id),
                ),
              );
            } else {
              showDialog(
                context: context,
                builder:
                    (ctx) =>
                        PurchaseInvoiceDetailDialog(invoiceId: item.id),
              );
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: isSelectable
                      ? (val) {
                          setState(() {
                            if (val == true) {
                              _selectedInvoiceIds.add(item.id);
                            } else {
                              _selectedInvoiceIds.remove(item.id);
                            }
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description.isNotEmpty
                            ? item.description
                            : "Fatura",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (invoiceDate != null)
                            Text(
                              "Tarih: ${dateFmt.format(invoiceDate)}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            "Vade: ${dueDate != null ? dateFmt.format(dueDate) : '-'}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(item.initialAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (!isPaid)
                      Text(
                        "Kalan: ${currency.format(item.remainingAmount)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.redAccent,
                        ),
                      )
                    else
                      const Text(
                        "Ödendi",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
