import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';

class NonTenantProductInfoDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const NonTenantProductInfoDialog({super.key, required this.data});

  @override
  State<NonTenantProductInfoDialog> createState() => _NonTenantProductInfoDialogState();
}

class _NonTenantProductInfoDialogState extends State<NonTenantProductInfoDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = _extractDetails(widget.data);
    final imageUrl = ImageUtils.getImageUrl(
      widget.data['custom_image_path']?.toString(),
      widget.data['full_image_url']?.toString(),
    );
    final barcode = widget.data['barcode']?.toString() ?? '-';
    final manufacturer = widget.data['manufacturer']?.toString() ?? '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Ürün Bilgisi",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Genel Bilgiler'),
                Tab(text: 'Detaylar'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: imageUrl == null
                                ? const Icon(Icons.medication, size: 56, color: AppColors.primary)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _infoRow("Ürün Adı", widget.data['name']?.toString() ?? 'İsimsiz ürün'),
                        _infoRow("Barkod", barcode),
                        _infoRow("Firma", manufacturer),
                        _infoRow("Klinik Kaydı", "Bu ürün henüz kliniğinize tanımlı değil"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: const Text(
                            "Bu ekran yalnızca bilgilendirme amaçlıdır. Ürünü kliniğinize eklemek için barkod eşleştirme adımını kullanabilirsiniz.",
                            style: TextStyle(fontSize: 12.5, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: details.isEmpty
                        ? Center(
                            child: Text(
                              "Bu ürün için detay bilgisi bulunamadı.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : Column(
                            children: details.entries
                                .map((e) => _detailCard(e.key, _formatDetailValue(e.value)))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Kapat"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _extractDetails(Map<String, dynamic> data) {
    final local = data['local_details'];
    if (local is Map<String, dynamic>) {
      final d = local['details'];
      if (d is Map<String, dynamic>) return d;
      return local;
    }
    final details = data['details'];
    if (details is Map<String, dynamic>) return details;
    return <String, dynamic>{};
  }

  String _formatDetailValue(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
