import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../data/models/purchase_invoice_detail_model.dart';
import '../providers/dashboard_provider.dart';

class PurchaseInvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const PurchaseInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<PurchaseInvoiceDetailScreen> createState() =>
      _PurchaseInvoiceDetailScreenState();
}

class _PurchaseInvoiceDetailScreenState
    extends ConsumerState<PurchaseInvoiceDetailScreen> {
  PurchaseInvoiceDetailModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(dashboardRepositoryProvider);
    try {
      final data = await repo.getPurchaseInvoiceDetail(widget.invoiceId);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
          _error = data == null ? 'Fatura bulunamadı.' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatura Detayı'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : _data == null
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(_data!, dateFormat),
                                  const SizedBox(height: 16),
                                  _buildItemsTable(_data!.items, currency),
                                  const SizedBox(height: 16),
                                  _buildSummary(_data!, currency),
                                  const SizedBox(height: 16),
                                  _buildSupplierDebtSection(
                                    _data!,
                                    currency,
                                    dateFormat,
                                  ),
                                  if (_data!.payments.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildPaymentsSection(
                                      _data!.payments,
                                      currency,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildHeader(PurchaseInvoiceDetailModel d, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.supplierName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (d.supplierPhone != null && d.supplierPhone!.isNotEmpty)
            Text(
              'Tel: ${d.supplierPhone}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _headerChip('Fatura No', d.invoiceNo),
              _headerChip('Fatura Tarihi', dateFormat.format(d.invoiceDate)),
              _headerChip(
                'Vade',
                d.dueDate != null ? dateFormat.format(d.dueDate!) : '—',
              ),
              _headerChip('Kaydeden', d.createdByUser ?? '—'),
            ],
          ),
          if (d.note != null && d.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Not: ${d.note}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildItemsTable(
    List<PurchaseInvoiceItemDetailModel> items,
    NumberFormat currency,
  ) {
    const rowHeight = 88.0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    _DetailHeaderCell('Ürün', width: 180),
                    _DetailHeaderCell('Parti / SKT', width: 110),
                    _DetailHeaderCell('Miktar', width: 60),
                    _DetailHeaderCell('Alış (₺)', width: 80),
                    _DetailHeaderCell('Satış (₺)', width: 80),
                    _DetailHeaderCell('İskonto %', width: 80),
                    _DetailHeaderCell('KDV %', width: 60),
                    _DetailHeaderCell('Net Toplam', width: 100),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: Colors.grey.shade300),
                    SizedBox(
                      height: rowHeight,
                      child: Container(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFF3F6FB),
                        child: Row(
                          children: [
                            _DetailDataCell(
                              width: 180,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  items[i].productName,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            _DetailDataCell(
                              width: 110,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    items[i].batchNo ?? '—',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    items[i].expirationDate != null
                                        ? DateFormat('dd.MM.yy')
                                            .format(items[i].expirationDate!)
                                        : '—',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _DetailDataCell(
                              width: 60,
                              child: Center(
                                child: Text(
                                  items[i].quantity.round().toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            _DetailDataCell(
                              width: 80,
                              child: Center(
                                child: Text(
                                  currency.format(items[i].unitPrice),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            _DetailDataCell(
                              width: 80,
                              child: Center(
                                child: Text(
                                  currency.format(items[i].sellingPrice),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ),
                            _DetailDataCell(
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${items[i].discountRate}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${items[i].discountRate2}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${items[i].discountRate3}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            _DetailDataCell(
                              width: 60,
                              child: Center(
                                child: Text(
                                  items[i].taxRate.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            _DetailDataCell(
                              width: 100,
                              child: Text(
                                currency.format(items[i].lineTotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(PurchaseInvoiceDetailModel d, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Fatura Özeti',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _summaryRow('Toplam Brüt', currency.format(d.totalGrossAmount)),
          _summaryRow('İndirim', '- ${currency.format(d.totalDiscountAmount)}'),
          _summaryRow('KDV', currency.format(d.totalVatAmount)),
          _summaryRow(
            'Net Tutar',
            currency.format(d.totalNetAmount),
            bold: true,
          ),
          const Divider(height: 16),
          _summaryRow(
            'Ödenen',
            currency.format(d.paidAmount),
            color: Colors.green.shade700,
          ),
          _summaryRow(
            'Kalan Borç',
            currency.format(d.remainingAmount),
            color: d.remainingAmount > 0 ? Colors.red : Colors.green.shade700,
          ),
          _summaryRow(
            'Ödeme Durumu',
            _paymentStatusLabel(d.paymentStatus),
          ),
        ],
      ),
    );
  }

  String _paymentStatusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'PAID':
        return 'Ödendi';
      case 'PARTIAL':
        return 'Kısmi Ödeme';
      default:
        return 'Ödenmedi';
    }
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierDebtSection(
    PurchaseInvoiceDetailModel d,
    NumberFormat currency,
    DateFormat dateFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_center,
                size: 20,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tedarikçiye Toplam Borç',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(d.supplierTotalDebt),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          if (d.supplierDueDates.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Açık faturalar ve vadeler:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...d.supplierDueDates.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        'Fatura ${e.invoiceNo}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.dueDate != null
                            ? dateFormat.format(e.dueDate!)
                            : '—',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      currency.format(e.remainingAmount),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(
    List<PurchaseInvoicePaymentModel> payments,
    NumberFormat currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu faturaya yapılan ödemeler',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...payments.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${p.paymentMethod} - ${DateFormat('dd.MM.yyyy HH:mm').format(p.processedAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    currency.format(p.amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeaderCell extends StatelessWidget {
  final String title;
  final double width;

  const _DetailHeaderCell(this.title, {required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.visible,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailDataCell extends StatelessWidget {
  final double width;
  final Widget child;

  const _DetailDataCell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: child,
    );
  }
}

