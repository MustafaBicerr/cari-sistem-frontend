import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/data/models/transaction_master_model.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dialogs/transaction_advanced_filter_dialog.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_filter_provider.dart'; // Filtre Provider'ı ekledik

// 🔥 AÇILIŞ SENARYOLARI (VIEW TYPES)
enum TransactionViewType {
  none, // Standart (Filtresiz)
  dailyTurnover, // Günlük Ciro (Sadece Ödenenler + Bugün)
  totalDebt, // Toplam Alacak (Sadece Borçlular + Azalan Sıralama)
  customer, // Belirli bir müşterinin tüm işlemleri
}

class TransactionMasterDialog extends ConsumerStatefulWidget {
  final TransactionViewType viewType; // Hangi modda açılacak?
  final String? customerId;
  final String? customerName;

  const TransactionMasterDialog({
    super.key,
    this.viewType = TransactionViewType.none, // Varsayılan boş
    this.customerId,
    this.customerName,
  });

  @override
  ConsumerState<TransactionMasterDialog> createState() =>
      _TransactionMasterDialogState();
}

class _TransactionMasterDialogState
    extends ConsumerState<TransactionMasterDialog> {
  @override
  void initState() {
    super.initState();
    // Widget çizildikten hemen sonra filtreleri ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialFilters();
    });
  }

  void _applyInitialFilters() {
    final notifier = ref.read(transactionFilterProvider.notifier);

    // Önce her şeyi temizle
    notifier.clearFilters();

    switch (widget.viewType) {
      case TransactionViewType.dailyTurnover:
        // SENARYO 1: GÜNLÜK CİRO
        // Sadece 'PAID' ve 'PARTIAL' olanları getir (Kasaya para girenler)
        // Sıralama: En yeni en üstte
        notifier.toggleStatus('PAID');
        notifier.toggleStatus('PARTIAL');
        // Not: Backend zaten 'date' parametresi ile bugünü getirecek,
        // client-side filtrede ayrıca tarih süzmeye gerek yok.
        break;

      case TransactionViewType.totalDebt:
        // SENARYO 2: GENEL ALACAK (BORÇLAR)
        // Sadece 'UNPAID' ve 'PARTIAL' (Kalan borcu olanlar)
        // Sıralama: En büyük borç en üstte
        notifier.toggleStatus('UNPAID');
        notifier.toggleStatus('PARTIAL');
        notifier.setSortOption('debt_desc'); // Borca göre azalan
        notifier.setAmountFilterType(
          'DEBT',
        ); // Tutar gösterimi borç odaklı olsun
        break;

      case TransactionViewType.customer:
      case TransactionViewType.none:
        // Hiçbir şey yapma, tertemiz liste.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Backend'e "Hangi Tarih?" sorusu
    // Eğer Ciro modundaysak BUGÜNÜ gönder, Borç modundaysak TÜM ZAMANI (null) gönder.
    // Çünkü borç 3 ay öncesinden de kalmış olabilir.
    String? dateParam;
    if (widget.viewType == TransactionViewType.dailyTurnover) {
      dateParam = DateTime.now().toIso8601String().split('T')[0];
    } else {
      dateParam = null; // Tüm zamanlar
    }

    // Veri kaynağı: dashboard geneli mi, yoksa belirli bir müşteri mi?
    final masterAsync =
        widget.viewType == TransactionViewType.customer &&
                widget.customerId != null
            ? ref.watch(customerTransactionsProvider(widget.customerId!))
            : ref.watch(transactionMasterProvider(dateParam));

    final filteredTransactions =
        ref.watch(filteredTransactionsProvider(masterAsync));

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Container(
        width: isMobile ? size.width : 950,
        height: size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeaderSection(context, ref, isMobile),
            const SizedBox(height: 16),

            // --- FİLTRE CHIPLERİ ---
            _buildQuickFilters(ref),
            const Divider(height: 24),

            // --- LİSTE ---
            Expanded(
              child: masterAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, s) => Center(
                      child: Text(
                        "Hata: $e",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                data: (_) {
                  if (filteredTransactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_off,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Kriterlere uygun kayıt bulunamadı.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder:
                        (context, index) => _MasterListItem(
                          item: filteredTransactions[index],
                          isMobile: isMobile,
                        ),
                  );
                },
              ),
            ),

            // --- FOOTER ---
            if (filteredTransactions.isNotEmpty)
              _buildFooterSummary(filteredTransactions),
          ],
        ),
      ),
    );
  }

  // Header: Başlık + Arama + Butonlar
  Widget _buildHeaderSection(
    BuildContext context,
    WidgetRef ref,
    bool isMobile,
  ) {
    return Row(
      children: [
        // Mobilde Başlık Gizlenebilir veya Küçültülebilir
        if (!isMobile) ...[
          Text(
            widget.viewType == TransactionViewType.customer &&
                    widget.customerName != null
                ? "İşlem Gezgini - ${widget.customerName}"
                : "İşlem Gezgini",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 24),
        ],

        // Arama Barı (Expanded)
        Expanded(
          child: TextField(
            onChanged:
                (val) => ref
                    .read(transactionFilterProvider.notifier)
                    .setSearchQuery(val),
            decoration: InputDecoration(
              hintText: "Müşteri, Ürün, Kasiyer Ara...",
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Sıralama Butonu (Popup Menu)
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: "Sırala",
          onSelected:
              (val) => ref
                  .read(transactionFilterProvider.notifier)
                  .setSortOption(val),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'date_desc',
                  child: Text("Tarih (Yeniden Eskiye)"),
                ),
                const PopupMenuItem(
                  value: 'date_asc',
                  child: Text("Tarih (Eskiden Yeniye)"),
                ),
                const PopupMenuItem(
                  value: 'amount_desc',
                  child: Text("Tutar (Yüksekten Düşüğe)"),
                ),
                const PopupMenuItem(
                  value: 'debt_desc',
                  child: Text("Borç (Yüksekten Düşüğe)"),
                ),
              ],
        ),

        // Gelişmiş Filtre Butonu
        IconButton(
          onPressed: () {
            // TODO: Gelişmiş Filtre Dialogunu Aç
            showDialog(
              context: context,
              builder: (context) => const TransactionAdvancedFilterDialog(),
            );

            print("Gelişmiş filtre açılacak");
          },
          icon: const Icon(Icons.filter_list),
          tooltip: "Gelişmiş Filtre",
        ),

        // Kapat Butonu
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: Colors.grey,
        ),
      ],
    );
  }

  // Hızlı Filtre Chipleri
  Widget _buildQuickFilters(WidgetRef ref) {
    final state = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Statü Chipleri
          _buildFilterChip(
            "Ödendi",
            state.selectedPaymentStatuses.contains('PAID'),
            () => notifier.toggleStatus('PAID'),
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            "Kısmi",
            state.selectedPaymentStatuses.contains('PARTIAL'),
            () => notifier.toggleStatus('PARTIAL'),
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            "Borçlu",
            state.selectedPaymentStatuses.contains('UNPAID'),
            () => notifier.toggleStatus('UNPAID'),
            Colors.red,
          ),

          const VerticalDivider(
            width: 24,
            thickness: 1,
            indent: 8,
            endIndent: 8,
          ),

          // Yöntem Chipleri
          _buildFilterChip(
            "Nakit",
            state.selectedPaymentMethods.contains('CASH'),
            () => notifier.toggleMethod('CASH'),
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            "Kart",
            state.selectedPaymentMethods.contains('CREDIT_CARD'),
            () => notifier.toggleMethod('CREDIT_CARD'),
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: color,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? color : Colors.transparent),
      ),
    );
  }

  Widget _buildFooterSummary(List<TransactionMasterModel> items) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    double totalTurnover = 0;
    double totalReceivable = 0;

    for (var item in items) {
      totalTurnover += item.paidAmount;
      totalReceivable += item.remainingAmount;
    }

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "${items.length} Kayıt",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            "Toplam Ciro: ${currency.format(totalTurnover)}",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Toplam Alacak: ${currency.format(totalReceivable)}",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// --- LİSTE ELEMANI (ZAM DETAYLARIYLA BİRLİKTE) ---
class _MasterListItem extends StatefulWidget {
  final TransactionMasterModel item;
  final bool isMobile;
  const _MasterListItem({required this.item, required this.isMobile});

  @override
  State<_MasterListItem> createState() => _MasterListItemState();
}

class _MasterListItemState extends State<_MasterListItem> {
  bool isExpanded = false;

  // Enflasyon Farkı Hesapla
  double get totalInflationDiff {
    double diff = 0;
    for (var prod in widget.item.items) {
      if (prod.paymentStatus == 'UNPAID' &&
          prod.currentPrice > prod.snapshotPrice) {
        diff += (prod.currentPrice - prod.snapshotPrice) * prod.quantity;
      }
    }
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final item = widget.item;

    // Renk ve İkon Mantığı
    Color statusColor;
    IconData statusIcon;
    if (item.transactionStatus == 'PAID') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else if (item.transactionStatus == 'PARTIAL') {
      statusColor = Colors.orange;
      statusIcon = Icons.timelapse;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    }

    final inflationDiff = totalInflationDiff;
    final currentTotalDebt = item.remainingAmount + inflationDiff;

    return Column(
      children: [
        // 1. ÖZET SATIR
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
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
                          Text(
                            item.timeStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.paymentMethod,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
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
                      currency.format(item.finalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.remainingAmount > 0)
                      Text(
                        "Kalan: ${currency.format(item.remainingAmount)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        "Tahsil Edildi",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
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

        // 2. DETAY ALANI (Accordion): header yatay scroll, ürün listesi dikey+yatay scroll (sabit yükseklik)
        if (isExpanded)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: uzun metin taşmasın diye yatay scroll (sabit yükseklik)
                SizedBox(
                  height: 44,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.cashierName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (inflationDiff > 0) ...[
                          Text(
                            "Zam Farkı: ${currency.format(inflationDiff)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _showInflationDetailsDialog(
                              context,
                              item.items,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("|", style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text(
                            "Güncel Borç: ${currency.format(currentTotalDebt)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(),

                // Ürün listesi: sabit yükseklik (220px), dikey scroll; tek yatay scroll ile tüm satırlar birlikte (zebra)
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      height: 36.0 * item.items.length,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 600),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final entry
                                  in item.items.asMap().entries)
                                Container(
                                  height: 36,
                                  color: entry.key.isEven
                                      ? Colors.white
                                      : const Color(0xFFF3F6FB),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 260,
                                        child: RichText(
                                          text: TextSpan(
                                            text:
                                                "${entry.value.productName} (x${entry.value.quantity.toStringAsFixed(0)}) ",
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: entry.value
                                                            .paymentStatus ==
                                                        'PAID'
                                                    ? "(Ödendi)"
                                                    : "(Ödenmedi)",
                                                style: TextStyle(
                                                  color: entry.value
                                                              .paymentStatus ==
                                                          'PAID'
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 120,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (!(entry.value.paymentStatus ==
                                                    'PAID') &&
                                                (entry.value.currentPrice >
                                                    entry.value
                                                        .snapshotPrice)) ...[
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
                                                onTap: () =>
                                                    _showProductHistoryDialog(
                                                  context,
                                                  entry.value,
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
                                              currency.format(
                                                entry.value.displayUnitPrice,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: !(entry.value
                                                            .paymentStatus ==
                                                        'PAID') &&
                                                        (entry.value
                                                                .currentPrice >
                                                            entry.value
                                                                .snapshotPrice)
                                                    ? Colors.red
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          currency.format(
                                            entry.value.displayTotalPrice,
                                          ),
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- DIALOGLAR (RESTORE EDİLDİ) ---

  // 1. Genel Zam Detayları (Header Butonu)
  void _showInflationDetailsDialog(
    BuildContext context,
    List<MasterItem> items,
  ) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
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
  void _showProductHistoryDialog(BuildContext context, MasterItem item) {
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
              height: 300,
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
