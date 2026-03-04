import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/widgets/section_card.dart';
import 'package:mobile/core/widgets/section_title.dart';
import '../providers/opening_stock_provider.dart';
import '../widgets/opening_stocks/opening_stock_header.dart';
import '../widgets/opening_stocks/opening_stock_items_zone.dart';

class OpeningStockScreen extends ConsumerWidget {
  const OpeningStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("İlk Stok Girişi"),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle("Temel Bilgiler"),
              const SizedBox(height: 8),

              SectionCard(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: const OpeningStockHeader(),
                ),
              ),

              const SizedBox(height: 28),

              const SectionTitle("Ürünler"),
              const SizedBox(height: 8),

              SectionCard(child: const OpeningStockItemsZone()),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined),
            label:
                state.isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text("Stok Kaydını Oluştur"),
            onPressed:
                state.isLoading
                    ? null
                    : () async {
                      try {
                        await notifier.submitOpeningStock();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Opening stok başarıyla kaydedildi.",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
