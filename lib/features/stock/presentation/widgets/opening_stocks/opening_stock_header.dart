import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/opening_stock_provider.dart';

class OpeningStockHeader extends ConsumerWidget {
  const OpeningStockHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE ROW
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: Colors.black,
              ),
              const SizedBox(width: 8),

              const Text(
                "Giriş Tarihi",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(width: 20),

              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.entryDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    notifier.setEntryDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 147, 246, 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "${state.entryDate.day}.${state.entryDate.month}.${state.entryDate.year}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // NOTE + INFO
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOTE FIELD
              Expanded(
                flex: 2,
                child: TextField(
                  minLines: 5,
                  maxLines: 8,
                  // textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    fillColor: Colors.white24,
                    labelText: "Not (Opsiyonel)",
                    floatingLabelAlignment: FloatingLabelAlignment.start,
                    // hintText:
                    //     "Açılış stok kaydı hakkında bir not ekleyebilirsiniz...",
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: notifier.setNote,
                ),
              ),

              const SizedBox(width: 16),

              // INFO BOX
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 22,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: "Bu ekran, kliniğiniz için "),
                              TextSpan(
                                text: "başlangıç stoklarını tanımlamak",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: " amacıyla kullanılır.\n\n"),
                              TextSpan(text: "Öncelikle "),
                              TextSpan(
                                text: "stok giriş tarihini",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: " belirleyebilir ve isteğe bağlı bir ",
                              ),
                              TextSpan(
                                text: "not",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    " ekleyebilirsiniz.\n\nArdından arama alanını kullanarak ",
                              ),
                              TextSpan(
                                text: "ürünleri seçip",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    " miktar, fiyat ve diğer bilgileri girerek ",
                              ),
                              TextSpan(
                                text:
                                    "açılış stok listenizi oluşturabilirsiniz.",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
