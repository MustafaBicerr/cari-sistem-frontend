import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AddBarcodeDialog açıkken parent wrapper barcode'u consume etmesin.
bool barcodeDialogOpen = false;

/// Barkod okuyucu (USB/Bluetooth) ile gelen tuş olaylarını yakalar.
/// Hızlı karakter girişi + Enter = barkod olarak işlenir.
/// Barkod tespit edildiğinde event consume edilir (TextField'a gitmez).
/// Yavaş yazım (>150ms aralık) = kullanıcı yazıyor, buffer temizlenir.
class BarcodeListenerWrapper extends StatefulWidget {
  final Widget child;
  final void Function(String barcode) onBarcodeScanned;
  final void Function()? onClearFocusedField;

  const BarcodeListenerWrapper({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.onClearFocusedField,
  });

  @override
  State<BarcodeListenerWrapper> createState() => _BarcodeListenerWrapperState();
}

class _BarcodeListenerWrapperState extends State<BarcodeListenerWrapper> {
  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeyTime;
  bool _isScanning = false;
  static const _maxIntervalMs = 150;

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (barcodeDialogOpen) return false;
    if (!mounted) return false;

    // Sadece aktif route üzerindeki listener barkod işlesin.
    // Aksi halde arka planda açık kalan ekranlar da aynı barkodu consume edebiliyor.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final now = DateTime.now();
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter;

    if (isEnter) {
      if (_buffer.isNotEmpty) {
        final barcode = _buffer.toString();
        _buffer.clear();
        _lastKeyTime = null;
        _isScanning = false;
        widget.onClearFocusedField?.call();
        widget.onBarcodeScanned(barcode);
        return true;
      }
      return false;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      final gap = _lastKeyTime != null
          ? now.difference(_lastKeyTime!).inMilliseconds
          : 999;

      if (gap > _maxIntervalMs) {
        _buffer.clear();
        _isScanning = false;
      }

      _lastKeyTime = now;
      _buffer.write(event.character);

      if (_buffer.length >= 2 || _isScanning) {
        _isScanning = true;
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
