import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/current_accounts/data/models/repositories/customer_repository.dart';
import 'package:mobile/features/current_accounts/data/models/repositories/supplier_repository.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/warehouse_model.dart';

// --- REPOSITORY PROVIDERS ---
final customerRepositoryProvider = Provider(
  (ref) => CustomerRepository(ref.read(apiClientProvider)),
);

final supplierRepositoryProvider = Provider(
  (ref) => SupplierRepository(ref.read(apiClientProvider)),
);

// --- LIST PROVIDERS ---

// 1. Müşteri Listesi
final customerListProvider = FutureProvider.autoDispose<List<CustomerModel>>((
  ref,
) async {
  final repo = ref.read(customerRepositoryProvider);
  return repo.getAllCustomers();
});

// 2. Tedarikçi Listesi
final supplierListProvider = FutureProvider.autoDispose<List<SupplierModel>>((
  ref,
) async {
  final repo = ref.read(supplierRepositoryProvider);
  return repo.getAllSuppliers();
});

// --- AUTOCOMPLETE LOGIC (Debouncing) ---

// Kullanıcının yazdığı arama metnini tutan state
final warehouseSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

// Arama sonuçlarını getiren provider (Debounce mantığı içerir)
final warehouseSearchResultsProvider = FutureProvider.autoDispose<
  List<WarehouseModel>
>((ref) async {
  final query = ref.watch(warehouseSearchQueryProvider);

  // Eğer sorgu boşsa veya çok kısaysa boş liste dön
  if (query.length < 2) return [];

  // Debounce: Kullanıcının yazmayı bitirmesini bekle (Örn: 500ms)
  // Riverpod'da bunu "Timer" ile simüle etmeye gerek yok, FutureProvider zaten
  // en son gelen isteği işler ama biz yine de istek trafiğini azaltmak için bir gecikme koyabiliriz.
  // Ancak FutureProvider içinde "delay" koymak UI'ı bekletir.
  // En temiz debounce UI tarafında text alanında yapılır ama burada basitçe repo'yu çağırıyoruz.

  final repo = ref.read(supplierRepositoryProvider);
  return repo.searchOfficialWarehouses(query);
});
