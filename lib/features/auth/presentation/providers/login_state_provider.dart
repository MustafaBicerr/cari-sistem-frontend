import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Şifre Gözü (Gizle/Göster) Durumu
final passwordVisibilityProvider = StateProvider<bool>((ref) => true);

// Loading Durumu (Giriş butonuna basınca dönecek mi?)
final isLoadingProvider = StateProvider<bool>((ref) => false);
