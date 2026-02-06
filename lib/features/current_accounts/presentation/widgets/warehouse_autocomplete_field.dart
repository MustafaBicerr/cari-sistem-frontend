import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/warehouse_model.dart';
import '../providers/account_provider.dart';

class WarehouseAutocompleteField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(WarehouseModel) onSelected;

  const WarehouseAutocompleteField({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  @override
  ConsumerState<WarehouseAutocompleteField> createState() =>
      _WarehouseAutocompleteFieldState();
}

class _WarehouseAutocompleteFieldState
    extends ConsumerState<WarehouseAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Yazarken dinle
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    // Debounce: Sürekli istek atma, 300ms bekle
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final text = widget.controller.text;
      // Provider'ı güncelle (İstek atar)
      ref.read(warehouseSearchQueryProvider.notifier).state = text;

      if (text.length >= 2) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return; // Zaten açıksa tekrar açma

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 48, // Padding payı
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 60), // Inputun hemen altına
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: Consumer(
                  builder: (context, ref, child) {
                    final searchAsync = ref.watch(
                      warehouseSearchResultsProvider,
                    );

                    return searchAsync.when(
                      data: (results) {
                        if (results.isEmpty) return const SizedBox.shrink();
                        return ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final warehouse = results[index];
                            return ListTile(
                              title: Text(
                                warehouse.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${warehouse.city ?? ''} / ${warehouse.district ?? ''}",
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                              ),
                              onTap: () {
                                widget.onSelected(warehouse);
                                _removeOverlay(); // Seçince kapat
                              },
                            );
                          },
                        );
                      },
                      loading:
                          () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: "Firma Adı (Ecza Deposu Ara)",
          hintText: "Örn: Selçuk Ecza...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}
