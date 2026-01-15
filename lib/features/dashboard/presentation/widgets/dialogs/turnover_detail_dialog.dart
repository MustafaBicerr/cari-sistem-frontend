import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/data/models/turnover_detail_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';

class TurnoverDetailDialog extends ConsumerWidget {
  const TurnoverDetailDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(turnoverDialogProvider(null));
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600; // Mobil kontrolü

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Container(
        // Mobilde ekranı tam kaplamasın ama geniş olsun
        width: isMobile ? size.width : 700,
        height: size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Günlük Ciro Hareketleri",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Kasaya giren tüm nakit ve kart işlemleri",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // Liste
            Expanded(
              child: detailsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, s) => Center(
                      child: Text(
                        "Hata: $e",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                data: (details) {
                  if (details.isEmpty)
                    return const Center(child: Text("Bugün henüz işlem yok."));

                  return ListView.separated(
                    itemCount: details.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder:
                        (context, index) => _TurnoverListItem(
                          item: details[index],
                          isMobile: isMobile,
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

class _TurnoverListItem extends StatefulWidget {
  final TurnoverDetailModel item;
  final bool isMobile;
  const _TurnoverListItem({required this.item, required this.isMobile});

  @override
  State<_TurnoverListItem> createState() => _TurnoverListItemState();
}

class _TurnoverListItemState extends State<_TurnoverListItem> {
  bool isExpanded = false;

  // Enflasyon Farkını Hesapla (Sadece UNPAID ürünler için)
  double get totalInflationDiff {
    double diff = 0;

    // // 🔥🔥🔥 DEBUG 2: HESAPLAMA LOGLARI 🔥🔥🔥
    // debugPrint("\n🔎 ÜRÜN ANALİZİ BAŞLIYOR (${widget.item.customerName})");

    // for (var prod in widget.item.items) {
    //   final bool isUnpaid = prod.paymentStatus == 'UNPAID';
    //   final bool hasPriceHike = prod.currentPrice > prod.snapshotPrice;

    //   debugPrint("   📦 ${prod.productName}:");
    //   debugPrint("      -> Durum: ${prod.paymentStatus}");
    //   debugPrint("      -> Eski Fiyat (Snapshot): ${prod.snapshotPrice}");
    //   debugPrint("      -> Yeni Fiyat (Current): ${prod.currentPrice}");
    //   debugPrint(
    //     "      -> Zam Var mı?: $hasPriceHike (${prod.currentPrice} > ${prod.snapshotPrice})",
    //   );

    //   if (isUnpaid && hasPriceHike) {
    //     final itemDiff =
    //         (prod.currentPrice - prod.snapshotPrice) * prod.quantity;
    //     diff += itemDiff;
    //     debugPrint("      💰 FARK EKLENDİ: +$itemDiff");
    //   } else {
    //     debugPrint("      ⛔ FARK EKLENMEDİ (Ya ödendi ya da zam yok)");
    //   }
    // }
    // debugPrint("   ∑ TOPLAM ZAM FARKI: $diff\n");
    // // 🔥🔥🔥 DEBUG BİTİŞ 🔥🔥🔥

    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final item = widget.item;
    final isSale = item.category == 'SALE';
    final typeColor = isSale ? Colors.green : Colors.orange;

    // Hesaplamalar
    final inflationDiff = totalInflationDiff;
    final currentTotalDebt =
        (item.transactionTotalAmount - item.amount) +
        inflationDiff; // Kalan Borç + Zam Farkı

    return Column(
      children: [
        // 1. ÜST ÖZET KART (Aynı kalıyor)
        InkWell(
          onTap: () => setState(() => isExpanded = !isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSale
                        ? Icons.shopping_bag_outlined
                        : Icons.assignment_turned_in_outlined,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${item.timeStr} • ${item.description}",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(item.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.paymentMethod == 'CASH' ? 'NAKİT' : 'KART',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        // 2. DETAY ALANI (Burası Değişti)
        if (isExpanded)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BİLGİ VE ÖZET SATIRI ---
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Kasiyer: ${item.createdByUser}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Ödenen
                    if (item.transactionTotalAmount > item.amount) ...[
                      Text(
                        "Ödenen: ${currency.format(item.amount)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("|", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),

                      // 🔥 ZAM FARKI GÖSTERGESİ
                      if (inflationDiff > 0) ...[
                        Row(
                          children: [
                            Text(
                              "Zam Farkı: ${currency.format(inflationDiff)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Info Butonu
                            InkWell(
                              onTap:
                                  () => _showInflationDetailsDialog(
                                    context,
                                    item.items,
                                  ),
                              child: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text("|", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],

                      // Kalan Borç (Güncellenmiş Tutar)
                      Text(
                        "Kalan: ${currency.format(currentTotalDebt)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const Divider(),

                // --- ÜRÜN LİSTESİ ---
                if (item.items.isNotEmpty) ...[
                  // Başlıklar (Desktop)
                  if (!widget.isMobile)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 4,
                            child: Text(
                              "Satılan Ürünler",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Birim Fiyat",
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "Tutar",
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...item.items.map((prod) {
                    final isPaid = prod.paymentStatus == 'PAID';
                    final hasInflation =
                        !isPaid && (prod.currentPrice > prod.snapshotPrice);

                    final statusColor = isPaid ? Colors.green : Colors.red;
                    final statusText = isPaid ? "(Ödendi)" : "(Ödenmedi)";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child:
                          widget.isMobile
                              // MOBİL
                              ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text:
                                                "${prod.productName} (x${prod.quantity.toStringAsFixed(0)}) ",
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: statusText,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Birim Fiyat + Zam Uyarısı
                                        Row(
                                          children: [
                                            Text(
                                              "Birim: ${currency.format(prod.unitPrice)}",
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (hasInflation) ...[
                                              const SizedBox(width: 4),
                                              const Text(
                                                "Zamlandı",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              InkWell(
                                                onTap:
                                                    () =>
                                                        _showProductHistoryDialog(
                                                          context,
                                                          prod,
                                                        ),
                                                child: const Icon(
                                                  Icons.info,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currency.format(prod.total),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              )
                              // DESKTOP
                              : Row(
                                children: [
                                  // Ürün Adı
                                  Expanded(
                                    flex: 4,
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            "${prod.productName} (x${prod.quantity.toStringAsFixed(0)}) ",
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Birim Fiyat + Zam Uyarısı
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (hasInflation) ...[
                                          const Text(
                                            "Zamlandı",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap:
                                                () => _showProductHistoryDialog(
                                                  context,
                                                  prod,
                                                ),
                                            child: const Icon(
                                              Icons.info,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          currency.format(prod.unitPrice),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                hasInflation
                                                    ? Colors.red
                                                    : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Toplam
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      currency.format(prod.total),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    );
                  }),
                ] else
                  const Text(
                    "Detay yok.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // --- DIALOGLAR ---

  // 1. Genel Zam Detayları (Header Butonu)
  void _showInflationDetailsDialog(
    BuildContext context,
    List<TurnoverItem> items,
  ) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    // Sadece zamlanan ürünleri filtrele
    final affectedItems =
        items
            .where(
              (i) =>
                  i.paymentStatus == 'UNPAID' &&
                  i.currentPrice > i.snapshotPrice,
            )
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              "Zam Farkı Detayları",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: affectedItems.length,
                itemBuilder: (context, index) {
                  final item = affectedItems[index];
                  final diff =
                      (item.currentPrice - item.snapshotPrice) * item.quantity;

                  return Card(
                    elevation: 0,
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Satış Fiyatı: ${currency.format(item.snapshotPrice)}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            "Güncel Fiyat: ${currency.format(item.currentPrice)}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Fark: ${currency.format(item.currentPrice - item.snapshotPrice)} x ${item.quantity.toInt()}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "+${currency.format(diff)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Kapat"),
              ),
            ],
          ),
    );
  }

  // 2. Ürün Fiyat Geçmişi (Row Butonu)
  void _showProductHistoryDialog(BuildContext context, TurnoverItem item) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "${item.productName} Fiyat Geçmişi",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 350,
              height: 300, // Scroll için yükseklik
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Satış Anı: ${currency.format(item.snapshotPrice)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Şu An: ${currency.format(item.currentPrice)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const Text(
                    "Değişim Logları:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child:
                        item.priceHistory.isEmpty
                            ? const Text(
                              "Log kaydı yok.",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                            : ListView.builder(
                              itemCount: item.priceHistory.length,
                              itemBuilder: (context, index) {
                                final hist = item.priceHistory[index];
                                final date = DateTime.tryParse(hist.date);
                                final dateStr =
                                    date != null
                                        ? DateFormat(
                                          'dd.MM.yyyy HH:mm',
                                        ).format(date)
                                        : hist.date;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    "${currency.format(hist.oldPrice)} ➔ ${currency.format(hist.newPrice)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  leading: const Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Kapat"),
              ),
            ],
          ),
    );
  }
}
