import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/current_accounts/data/models/customer_model.dart';
import 'package:mobile/features/current_accounts/presentation/providers/account_provider.dart';
import 'package:mobile/features/current_accounts/presentation/screens/add_customer_screen.dart'; // AddCustomerScreen importu
import '../../../../core/theme/app_colors.dart';
import '../providers/sale_state_provider.dart';

class CustomerSelectionWidget extends ConsumerWidget {
  const CustomerSelectionWidget({super.key});

  // --- MANTIK: Müşteri Ekleme ve Oto-Seçim ---
  Future<void> _openAddCustomer(BuildContext context, WidgetRef ref) async {
    // 1. Ekranı Aç ve Sonucu Bekle
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );

    // 2. Eğer başarılı kayıt yapıldıysa (result dolu döner)
    if (result != null && result is CustomerModel) {
      debugPrint(
        "🆕 Yeni müşteri oluşturuldu: ${result.fullName} (ID: ${result.id})",
      );
      // Listeyi yenilemesini bekle (Network isteği)
      // Biraz manuel bir bekleme yapıyoruz ki backend veriyi yazabilsin
      // await Future.delayed(const Duration(milliseconds: 500));

      // Yenilenmiş listeyi çek
      // final customers = await ref.refresh(customerListProvider.future);

      // 3. Yeni eklenen müşteriyi bul (İsme veya Telefona göre eşleştir)
      try {
        // final newCustomer = result;
        //   (c) =>
        //       c.fullName == result.fullName && c.phone == result.phone;

        // 4. Müşteriyi Seç
        ref.read(saleStateProvider.notifier).selectCustomer(result);
      } catch (e) {
        // Tam eşleşme bulunamazsa sessiz kal veya en son ekleneni seç
        debugPrint("Otomatik seçim yapılamadı: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleState = ref.watch(saleStateProvider);
    final notifier = ref.read(saleStateProvider.notifier);
    final customersAsync = ref.watch(customerListProvider);

    // 1. DURUM: Müşteri Seçilmişse (KART GÖSTER)
    if (saleState.selectedCustomer != null) {
      final customer = saleState.selectedCustomer!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                customer.fullName.isNotEmpty
                    ? customer.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Bakiye: ₺${customer.currentBalance.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          customer.currentBalance > 0
                              ? AppColors.error
                              : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: notifier.removeCustomer,
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: "Müşteriyi Kaldır",
            ),
          ],
        ),
      );
    }

    // 2. DURUM: Seçim Yok (ARAMA + BUTON + ANONİM)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama Çubuğu ve Yanındaki Buton (Row İçinde)
        Row(
          children: [
            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<CustomerModel>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (saleState.isAnonymous)
                            return const Iterable<CustomerModel>.empty();
                          if (textEditingValue.text == '')
                            return const Iterable<CustomerModel>.empty();
                          return customers.where((CustomerModel option) {
                            return option.fullName.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        displayStringForOption:
                            (CustomerModel option) => option.fullName,

                        // 🔥 ÖZELLEŞTİRİLMİŞ DROPDOWN (Scroll Edilebilir Liste + Sabit Buton)
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(12),
                              // Genişliği TextField ile aynı yap
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Scroll Edilebilir Müşteri Listesi
                                    Expanded(
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (
                                          BuildContext context,
                                          int index,
                                        ) {
                                          final CustomerModel option = options
                                              .elementAt(index);
                                          return ListTile(
                                            title: Text(
                                              option.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(option.phone ?? ""),
                                            trailing: Text(
                                              "₺${option.currentBalance.toStringAsFixed(2)}",
                                            ),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),

                                    const Divider(height: 1),

                                    // 🔥 DROPDOWN ALTINDAKİ SABİT EKLEME BUTONU
                                    InkWell(
                                      onTap:
                                          () => _openAddCustomer(
                                            context,
                                            ref,
                                          ), // Aynı fonksiyonu kullan
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(12),
                                              ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Listede Yok - Yeni Müşteri Ekle",
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },

                        fieldViewBuilder: (
                          context,
                          controller,
                          focusNode,
                          onEditingComplete,
                        ) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            enabled: !saleState.isAnonymous, // Anonimse kitle
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.person_search_outlined,
                              ),
                              hintText:
                                  saleState.isAnonymous
                                      ? "Kaydedilmeyen müşteri seçili"
                                      : "Müşteri Ara...",
                              filled: true,
                              fillColor:
                                  saleState.isAnonymous
                                      ? Colors.grey[200]
                                      : AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          );
                        },
                        onSelected: (CustomerModel selection) {
                          notifier.selectCustomer(selection);
                        },
                      );
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text("Hata"),
              ),
            ),

            const SizedBox(width: 12),

            // 🔥 SEARCH BAR YANINDAKİ KARE BUTON (Sarı Bölge)
            if (!saleState.isAnonymous)
              Tooltip(
                message: "Hızlı Müşteri Ekle",
                child: InkWell(
                  onTap: () => _openAddCustomer(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48, // TextField ile aynı yükseklik
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary, // Vurgulu renk
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Anonim Seçeneği
        InkWell(
          onTap: () => notifier.toggleAnonymous(!saleState.isAnonymous),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: saleState.isAnonymous,
                onChanged: (val) => notifier.toggleAnonymous(val!),
                activeColor: AppColors.primary,
              ),
              const Text(
                "Kaydedilmeyen Müşteri (Hızlı Satış)",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
