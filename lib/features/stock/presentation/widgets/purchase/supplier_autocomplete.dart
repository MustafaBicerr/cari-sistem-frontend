import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';

class SupplierAutocomplete extends ConsumerStatefulWidget {
  const SupplierAutocomplete({super.key});

  @override
  ConsumerState<SupplierAutocomplete> createState() =>
      _SupplierAutocompleteState();
}

class _SupplierAutocompleteState extends ConsumerState<SupplierAutocomplete> {
  bool _isLoading = false;

  Future<List<Map<String, dynamic>>> _searchCombinedSuppliers(
    String query,
  ) async {
    if (query.length < 2) return [];
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Yerel Tedarikçileri Getir
      final localRes = await apiClient.dio.get('/suppliers');
      List<Map<String, dynamic>> localSuppliers =
          List<Map<String, dynamic>>.from(localRes.data)
              .where(
                (s) => s['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .map((s) => {...s, 'source': 'local'})
              .toList();

      // 🔥 MÜKERRER KAYIT ÖNLEME (DEDUPLICATION) İÇİN YEREL İSİMLERİ HAFIZAYA AL
      final Set<String> localNames =
          localSuppliers
              .map((s) => s['name'].toString().toLowerCase().trim())
              .toSet();

      // 2. Resmi Depoları Getir (Global)
      final globalRes = await apiClient.dio.get(
        '/suppliers/search-official',
        queryParameters: {'q': query},
      );

      // 🔥 EĞER GLOBAL DEPO, YERELDE ZATEN VARSA LİSTEYE EKLEME!
      List<Map<String, dynamic>> globalSuppliers =
          List<Map<String, dynamic>>.from(globalRes.data)
              .where(
                (s) =>
                    !localNames.contains(
                      s['name'].toString().toLowerCase().trim(),
                    ),
              ) // Filtre
              .map((s) => {...s, 'source': 'global'})
              .toList();

      setState(() => _isLoading = false);
      // Temizlenmiş birleştirilmiş liste
      return [...localSuppliers, ...globalSuppliers];
    } catch (e) {
      setState(() => _isLoading = false);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(purchaseFormProvider);

    // EĞER TEDARİKÇİ SEÇİLMİŞSE ŞIK KARTI GÖSTER, YOKSA ARAMA KUTUSUNU GÖSTER
    if (formState.supplierId != null && formState.supplierData != null) {
      return _buildSelectedSupplierCard(formState.supplierData!);
    }

    return _buildSearchBar(formState);
  }

  // --- 1. DURUM: ARAMA ÇUBUĞU GÖRÜNÜMÜ ---
  Widget _buildSearchBar(PurchaseFormState formState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Map<String, dynamic>>(
          optionsBuilder:
              (textEditingValue) =>
                  _searchCombinedSuppliers(textEditingValue.text),
          displayStringForOption: (option) => option['name'] ?? '',
          onSelected: (selection) {
            ref.read(purchaseFormProvider.notifier).selectSupplier(selection);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            final showLoader = _isLoading || formState.isSupplierLoading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    "Tedarikçi (Kayıtlı / Resmi Depo) *",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Örn: Selçuk Ecza...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.business,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon:
                        showLoader
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(
                              Icons.search,
                              color: Colors.grey,
                              size: 20,
                            ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isLocal = option['source'] == 'local';

                      return ListTile(
                        leading: Icon(
                          isLocal ? Icons.verified : Icons.cloud_download,
                          color:
                              isLocal ? AppColors.success : AppColors.primary,
                        ),
                        title: Text(
                          option['name'] ?? 'İsimsiz',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isLocal
                              ? "Klinikte Kayıtlı Tedarikçi"
                              : "Resmi Depo (Seçince Kaydedilir)",
                          style: TextStyle(
                            color:
                                isLocal
                                    ? AppColors.textSecondary
                                    : AppColors.primary.withOpacity(0.7),
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. DURUM: SEÇİLİ TEDARİKÇİ KARTI GÖRÜNÜMÜ ---
  Widget _buildSelectedSupplierCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(
          0.05,
        ), // Çok hafif mavi/ana renk arka plan
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Çarpı Butonu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Bilinmeyen Tedarikçi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['contact_person'] ??
                          data['manager'] ??
                          'Yetkili bilgisi yok',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Çarpı (Kaldır) Butonu
              IconButton(
                tooltip: "Tedarikçiyi Değiştir",
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () {
                  // Seçimi temizle ve arama çubuğunu geri getir
                  ref.read(purchaseFormProvider.notifier).clearSupplier();
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          // Detay Bilgileri (Wrap ile responsive dağılım)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.numbers,
                "VKN: ${data['tax_number'] ?? '-'}",
              ),
              _buildInfoChip(
                Icons.location_city,
                "${data['district'] ?? ''} ${data['city'] != null ? '/ ${data['city']}' : ''}",
              ),
              _buildInfoChip(Icons.phone, data['phone'] ?? 'Tel Yok'),
            ],
          ),
          if (data['address'] != null &&
              data['address'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['address'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Alt bilgiler için küçük şık chipler
  Widget _buildInfoChip(IconData icon, String text) {
    if (text.trim() == '' || text.trim() == '/') return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
