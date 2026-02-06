import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/supplier_model.dart';
import 'account_provider.dart'; // Repo providerları buradan alıyoruz

// 1. Seçili Müşteri Detayı (ID'ye göre)
final customerDetailProvider = FutureProvider.autoDispose
    .family<CustomerDetailResponse, String>((ref, id) async {
      final repo = ref.read(customerRepositoryProvider);
      return repo.getCustomerDetail(id);
    });

// 2. Seçili Tedarikçi Detayı (ID'ye göre)
final supplierDetailProvider = FutureProvider.autoDispose
    .family<SupplierDetailResponse, String>((ref, id) async {
      final repo = ref.read(supplierRepositoryProvider);
      return repo.getSupplierDetail(id);
    });
