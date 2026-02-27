import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/constants/api_constants.dart';
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
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      // 1. Yerel Tedarikçileri Getir (Klinikte kayıtlı olanlar)
      final localRes = await dio.get('/suppliers', options: options);
      List<Map<String, dynamic>> localSuppliers =
          List<Map<String, dynamic>>.from(localRes.data)
              .where(
                (s) => s['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .map((s) => {...s, 'source': 'local'})
              .toList();

      // 2. Resmi Depoları Getir (Global)
      final globalRes = await dio.get(
        '/suppliers/search-official',
        queryParameters: {'q': query},
        options: options,
      );
      List<Map<String, dynamic>> globalSuppliers =
          List<Map<String, dynamic>>.from(
            globalRes.data,
          ).map((s) => {...s, 'source': 'global'}).toList();

      // Sonuçları birleştir
      setState(() => _isLoading = false);
      return [...localSuppliers, ...globalSuppliers];
    } catch (e) {
      setState(() => _isLoading = false);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Map<String, dynamic>>(
          optionsBuilder:
              (textEditingValue) =>
                  _searchCombinedSuppliers(textEditingValue.text),
          displayStringForOption: (option) => option['name'] ?? '',
          onSelected: (selection) {
            // Bütün zekayı Provider'a devrettik.
            ref.read(purchaseFormProvider.notifier).selectSupplier(selection);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            final formState = ref.watch(
              purchaseFormProvider,
            ); // Tüm state'i izle

            if (formState.supplierName != null &&
                controller.text != formState.supplierName) {
              controller.text = formState.supplierName!;
            }

            // Hem arama yaparken hem de arka planda tedarikçi oluşturulurken loader dönsün
            final showLoader = _isLoading || formState.isSupplierLoading;

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: "Tedarikçi Ara (Kayıtlı veya Resmi Depolar) *",
                prefixIcon: const Icon(Icons.business),
                suffixIcon:
                    showLoader
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
}
