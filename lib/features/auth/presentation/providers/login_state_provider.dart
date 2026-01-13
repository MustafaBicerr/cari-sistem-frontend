import 'package:flutter_riverpod/legacy.dart';

// Şifre Gözü (Gizle/Göster) Durumu
final passwordVisibilityProvider = StateProvider<bool>((ref) => true);

// Loading Durumu
final isLoadingProvider = StateProvider<bool>((ref) => false);
