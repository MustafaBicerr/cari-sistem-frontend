import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../../data/models/purchase_invoice_detail_model.dart';
import '../../providers/dashboard_provider.dart';

/// E-fatura tarzı alım faturası detayı: header + ürünler tablosu (zebra, salt okunur) + özet + tedarikçi borç/vadeler.
class PurchaseInvoiceDetailDialog extends ConsumerStatefulWidget {
  final String invoiceId;

  const PurchaseInvoiceDetailDialog({super.key, required this.invoiceId});

  @override
  ConsumerState<PurchaseInvoiceDetailDialog> createState() =>
      _PurchaseInvoiceDetailDialogState();
}

class _PurchaseInvoiceDetailDialogState
    extends ConsumerState<PurchaseInvoiceDetailDialog> {
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
      if (mounted)
        setState(() {
          _data = data;
          _loading = false;
          _error = data == null ? 'Fatura bulunamadı.' : null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 920,
        constraints: const BoxConstraints(maxHeight: 900),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Fatura Detayı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_data != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Salt okunur',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_data != null)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(_data!, dateFormat),
                      const SizedBox(height: 20),
                      _buildItemsTable(_data!.items, currency),
                      const SizedBox(height: 20),
                      _buildSummary(_data!, currency),
                      const SizedBox(height: 16),
                      _buildSupplierDebtSection(_data!, currency, dateFormat),
                      if (_data!.payments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPaymentsSection(_data!.payments, currency),
                      ],
                    ],
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
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
            spacing: 24,
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
    const rowHeight = 100.0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık satırı — purchase_items_zone ile aynı görsel dil
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _DetailHeaderCell('Fotoğraf', width: 65),
                _DetailHeaderCell('Ürün Adı', width: 158),
                _DetailHeaderCell('Parti\nSKT', width: 86),
                _DetailHeaderCell('Miktar', width: 54),
                _DetailHeaderCell('Mal Faz.', width: 54),
                _DetailHeaderCell('Alış Fiyatı (₺)', width: 76),
                _DetailHeaderCell(
                  'Satış Fiyatı (₺)',
                  width: 76,
                  color: Colors.deepOrange,
                ),
                _DetailHeaderCell('Satır İsk. (%) [1, 2, 3]', width: 95),
                _DetailHeaderCell('KDV (%)', width: 48),
                _DetailHeaderCell(
                  'Net Toplam',
                  width: 86,
                  align: TextAlign.right,
                ),
              ],
            ),
          ),
          // Veri satırları — zebra + hücre bordürü (purchase_table_row ile uyumlu)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, i) {
              final item = items[i];
              final bg = i % 2 == 0 ? Colors.white : const Color(0xFFE3F2FD);
              return SizedBox(
                height: rowHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _DetailDataCell(
                        width: 65,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(
                              Icons.medication,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 158,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Text(
                            item.productName,
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
                        width: 86,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Text(
                                  '${item.batchNo ?? "—"}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrangeAccent,
                                  borderRadius: BorderRadius.circular(4),
                                  // border: Border.all(color: Colors.black),
                                ),
                                child: Text(
                                  item.expirationDate != null
                                      ? DateFormat(
                                        'dd.MM.yy',
                                      ).format(item.expirationDate!)
                                      : '—',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 54,
                        child: Center(
                          child: Text(
                            item.quantity.round().toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 54,
                        child: Center(
                          child: Text(
                            item.freeQuantity.round().toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 76,
                        child: Center(
                          child: Text(
                            currency.format(item.unitPrice),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 76,
                        child: Center(
                          child: Text(
                            currency.format(item.sellingPrice),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 95,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${item.discountRate}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                '${item.discountRate2}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                '${item.discountRate3}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 48,
                        child: Center(
                          child: Text(
                            item.taxRate.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      _DetailDataCell(
                        width: 86,
                        child: Center(
                          child: Text(
                            currency.format(item.lineTotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
          _summaryRow('Ödeme Durumu', _paymentStatusLabel(d.paymentStatus)),
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
                      width: 100,
                      child: Text(
                        'Fatura ${e.invoiceNo}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        e.dueDate != null ? dateFormat.format(e.dueDate!) : '—',
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

/// Başlık hücresi — purchase_items_zone _HeaderCell ile aynı görünüm
class _DetailHeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final TextAlign align;
  final Color? color;

  const _DetailHeaderCell(
    this.title, {
    required this.width,
    this.align = TextAlign.center,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        title,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          height: 1.25,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}

/// Veri hücresi — purchase_table_row _buildCell ile aynı (border right, padding)
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
