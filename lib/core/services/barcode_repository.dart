import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'barcode_service.dart';

final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  return BarcodeService(ref.read(apiClientProvider));
});
