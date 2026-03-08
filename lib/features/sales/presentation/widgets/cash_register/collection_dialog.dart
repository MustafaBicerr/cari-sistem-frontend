import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../providers/cash_register_provider.dart';

/// Tahsilat dialogu: Müşteri seç → Fişleri checkbox ile seç → Ödeme yöntemi (Nakit / Kart / Nakit+Kart) → Kaydet.
/// Tutar fiş seçiminden otomatik hesaplanır; serbest tutar girilmez.
class CollectionDialog extends ConsumerStatefulWidget {
  const CollectionDialog({super.key});

  @override
  ConsumerState<CollectionDialog> createState() => _CollectionDialogState();
}

class _CollectionDialogState extends ConsumerState<CollectionDialog> {
  final _searchCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();

  List<Map<String, dynamic>> _customerSuggestions = [];
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _debtSummary = [];
  final Set<String> _selectedTransactionIds = {};
  Map<String, dynamic>? _expandedTransaction;
  bool _loadingCustomers = false;
  bool _loadingDebt = false;
  bool _submitting = false;
  String _paymentMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    _searchCustomers('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cashCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String q) async {
    setState(() => _loadingCustomers = true);
    try {
      final repo = ref.read(financeRepositoryProvider);
      final list = await repo.searchCustomers(q.isEmpty ? null : q);
      if (mounted) setState(() {
        _customerSuggestions = list;
        _loadingCustomers = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _customerSuggestions = [];
        _loadingCustomers = false;
      });
    }
  }

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    final id = customer['id']?.toString();
    if (id == null) return;
    setState(() {
      _selectedCustomer = customer;
      _searchCtrl.text = customer['full_name']?.toString() ?? '';
      _debtSummary = [];
      _selectedTransactionIds.clear();
      _expandedTransaction = null;
      _cashCtrl.clear();
      _cardCtrl.clear();
      _loadingDebt = true;
    });
    try {
      final repo = ref.read(financeRepositoryProvider);
      final list = await repo.getCustomerDebtSummary(id);
      if (mounted) setState(() {
        _debtSummary = list;
        _loadingDebt = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _debtSummary = [];
        _loadingDebt = false;
      });
    }
  }

  void _toggleTransactionSelection(Map<String, dynamic> t) {
    final id = t['transaction_id']?.toString();
    if (id == null) return;
    setState(() {
      if (_selectedTransactionIds.contains(id)) {
        _selectedTransactionIds.remove(id);
      } else {
        _selectedTransactionIds.add(id);
      }
      if (_paymentMethod == 'CASH_CARD') {
        final total = selectedTotal;
        _cashCtrl.text = total.toStringAsFixed(2);
        _cardCtrl.text = '0.00';
      }
    });
  }

  double get selectedTotal {
    double sum = 0;
    for (final t in _debtSummary) {
      final id = t['transaction_id']?.toString();
      if (id != null && _selectedTransactionIds.contains(id)) {
        sum += _safeDouble(t['remaining_amount']);
      }
    }
    return sum;
  }

  Future<void> _toggleTransactionDetail(String transactionId) async {
    if (_expandedTransaction != null && _expandedTransaction!['id']?.toString() == transactionId) {
      setState(() => _expandedTransaction = null);
      return;
    }
    try {
      final repo = ref.read(financeRepositoryProvider);
      final detail = await repo.getTransactionDetail(transactionId);
      if (mounted && detail != null) setState(() => _expandedTransaction = detail);
    } catch (_) {}
  }

  Future<void> _submitCollection() async {
    final customerId = _selectedCustomer?['id']?.toString();
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir müşteri seçin.")),
      );
      return;
    }
    if (_selectedTransactionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az bir fiş işaretleyin.")),
      );
      return;
    }

    final total = selectedTotal;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seçilen fişlerde borç bulunamadı.")),
      );
      return;
    }

    if (_paymentMethod == 'CASH_CARD') {
      final cash = double.tryParse(_cashCtrl.text.replaceAll(',', '.')) ?? 0;
      final card = double.tryParse(_cardCtrl.text.replaceAll(',', '.')) ?? 0;
      if ((cash + card - total).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nakit + Kart toplamı (₺${(cash + card).toStringAsFixed(2)}) fiş toplamına (₺${total.toStringAsFixed(2)}) eşit olmalı.")),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(financeRepositoryProvider);
      await repo.submitCollection(
        customerId: customerId,
        transactionIds: _selectedTransactionIds.toList(),
        paymentMethod: _paymentMethod,
        cashAmount: _paymentMethod == 'CASH_CARD' ? (double.tryParse(_cashCtrl.text.replaceAll(',', '.')) ?? 0) : null,
        cardAmount: _paymentMethod == 'CASH_CARD' ? (double.tryParse(_cardCtrl.text.replaceAll(',', '.')) ?? 0) : null,
      );
      if (!mounted) return;
      ref.read(cashRegisterProvider.notifier).loadDailyData();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tahsilat kaydedildi.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = selectedTotal;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_circle_outline, color: AppColors.success, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Text("Tahsilat Yap", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Müşteri arama
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        labelText: "Müşteri ara",
                        hintText: "Ad veya telefon ile ara...",
                        prefixIcon: const Icon(Icons.person_search, color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: _loadingCustomers
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : null,
                      ),
                      onChanged: (v) => _searchCustomers(v),
                    ),

                    if (_customerSuggestions.isNotEmpty && _selectedCustomer == null) ...[
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _customerSuggestions.length,
                          itemBuilder: (_, i) {
                            final c = _customerSuggestions[i];
                            final name = c['full_name']?.toString() ?? '';
                            final balance = _safeDouble(c['current_balance']);
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.2), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text("Bakiye: ₺${balance.toStringAsFixed(2)}", style: TextStyle(color: balance > 0 ? AppColors.error : Colors.grey[600], fontSize: 13)),
                              onTap: () => _selectCustomer(c),
                            );
                          },
                        ),
                      ),
                    ],

                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 20),
                      Text("Borçlu fişler – Ödenecek olanları işaretleyin", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(height: 8),
                      if (_loadingDebt)
                        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                      else if (_debtSummary.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 10),
                              Expanded(child: Text("Bu müşteriye ait borçlu fiş yok.", style: TextStyle(color: Colors.grey[700], fontSize: 14))),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _debtSummary.length,
                          itemBuilder: (_, i) {
                            final t = _debtSummary[i];
                            final id = t['transaction_id']?.toString() ?? '';
                            final createdAt = t['created_at']?.toString() ?? '';
                            final remaining = _safeDouble(t['remaining_amount']);
                            final finalAmt = _safeDouble(t['final_amount']);
                            final isSelected = _selectedTransactionIds.contains(id);
                            final isExpanded = _expandedTransaction?['id']?.toString() == id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleTransactionSelection(t),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.success.withOpacity(0.08) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? AppColors.success.withOpacity(0.5) : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (_) => _toggleTransactionSelection(t),
                                              activeColor: AppColors.success,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.tryParse(createdAt) ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 2),
                                                  Text("Kalan: ₺${remaining.toStringAsFixed(2)} / Toplam: ₺${finalAmt.toStringAsFixed(2)}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                              onPressed: () => _toggleTransactionDetail(id),
                                            ),
                                          ],
                                        ),
                                        if (isExpanded && _expandedTransaction != null) _buildTransactionDetail(_expandedTransaction!),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      if (_selectedTransactionIds.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // Ödeme yöntemi
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: InputDecoration(
                            labelText: "Ödeme yöntemi",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CASH', child: Text("Nakit")),
                            DropdownMenuItem(value: 'CREDIT_CARD', child: Text("Kredi Kartı")),
                            DropdownMenuItem(value: 'CASH_CARD', child: Text("Nakit + Kart")),
                          ],
                          onChanged: _submitting ? null : (v) {
                            setState(() {
                              _paymentMethod = v ?? 'CASH';
                              if (_paymentMethod == 'CASH_CARD') {
                                _cashCtrl.text = total.toStringAsFixed(2);
                                _cardCtrl.text = '0.00';
                              } else {
                                _cashCtrl.clear();
                                _cardCtrl.clear();
                              }
                            });
                          },
                        ),
                        if (_paymentMethod == 'CASH_CARD') ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cashCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: "Nakit (₺)",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    prefixIcon: const Icon(Icons.payments, size: 20),
                                  ),
                                  onChanged: (_) {
                                    setState(() {
                                      final cash = double.tryParse(_cashCtrl.text.replaceAll(',', '.')) ?? 0;
                                      _cardCtrl.text = (total - cash).clamp(0, double.infinity).toStringAsFixed(2);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _cardCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: "Kart (₺)",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    prefixIcon: const Icon(Icons.credit_card, size: 20),
                                  ),
                                  onChanged: (_) {
                                    setState(() {
                                      final card = double.tryParse(_cardCtrl.text.replaceAll(',', '.')) ?? 0;
                                      _cashCtrl.text = (total - card).clamp(0, double.infinity).toStringAsFixed(2);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Sabit özet + Kaydet (dialoga çakılı)
            if (_selectedCustomer != null && _debtSummary.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedTransactionIds.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Ödenecek fişler", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            const SizedBox(height: 8),
                            ..._debtSummary.where((t) => _selectedTransactionIds.contains(t['transaction_id']?.toString())).map((t) {
                              final createdAt = t['created_at']?.toString() ?? '';
                              final remaining = _safeDouble(t['remaining_amount']);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.tryParse(createdAt) ?? DateTime.now()), style: const TextStyle(fontSize: 13)),
                                    Text("₺${remaining.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Toplam tahsilat", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                Text("₺${total.toStringAsFixed(2)}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (_submitting || _selectedTransactionIds.isEmpty || total <= 0) ? null : _submitCollection,
                        icon: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 22),
                        label: Text(_submitting ? "Kaydediliyor..." : "Tahsilatı kaydet"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(Map<String, dynamic> tx) {
    final items = tx['items'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...items.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final name = m['product_name']?.toString() ?? '';
            final qty = _safeDouble(m['quantity']);
            final unit = _safeDouble(m['unit_price']);
            final status = m['payment_status']?.toString() ?? 'UNPAID';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text("$name × $qty @ ₺${unit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'PAID' ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status == 'PAID' ? 'Ödendi' : 'Borçlu', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
