import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/responsive/responsive_layout.dart'; // ResponsiveLayout importunu projene göre kontrol et
import 'package:mobile/core/theme/app_colors.dart';

class ProductDetailsTab extends StatefulWidget {
  final TextEditingController groupCtrl;
  final TextEditingController firmCtrl;
  final TextEditingController animalCtrl;
  final TextEditingController shapeCtrl;
  final TextEditingController ingredientCtrl;
  final String? prospectus;
  final List<dynamic>? relatedDrugs;
  final XFile? selectedImage;
  final String? networkImageUrl;
  final VoidCallback onPickImage;

  const ProductDetailsTab({
    super.key,
    required this.groupCtrl,
    required this.firmCtrl,
    required this.animalCtrl,
    required this.shapeCtrl,
    required this.ingredientCtrl,
    this.prospectus,
    this.relatedDrugs,
    this.selectedImage,
    this.networkImageUrl,
    required this.onPickImage,
  });

  @override
  State<ProductDetailsTab> createState() => _ProductDetailsTabState();
}

class _ProductDetailsTabState extends State<ProductDetailsTab> {
  bool _isProspectusExpanded = false;
  bool _isRelatedDrugsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ÜST BÖLÜM (Tablo Bilgileri + Resim)
          // ResponsiveLayout yoksa direkt mobile layout'u column içinde kullanabilirsin.
          // Senin verdiğin koda sadık kalıyorum:
          ResponsiveLayout(
            mobile: Column(
              children: [
                _buildImageSection(height: 200),
                const SizedBox(height: 16),
                _buildLocalDetailsTable(),
              ],
            ),
            desktop: SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SOL: Tablo Bilgileri
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SingleChildScrollView(
                          child: _buildLocalDetailsTable(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // SAĞ: Ürün Resmi
                  Expanded(flex: 2, child: _buildImageSection(height: null)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. PROSPEKTÜS ALANI
          if (widget.prospectus != null && widget.prospectus!.isNotEmpty) ...[
            const Text(
              "Prospektüs Bilgisi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              firstChild: Text(
                widget.prospectus!,
                maxLines: 4, // Mobilde biraz daha fazla gösterelim
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              secondChild: Text(
                widget.prospectus!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              crossFadeState:
                  _isProspectusExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isProspectusExpanded = !_isProspectusExpanded;
                });
              },
              icon: Icon(
                _isProspectusExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              label: Text(
                _isProspectusExpanded ? "Daha Az Göster" : "Okumaya Devam Et",
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 3. MUADİL İLAÇLAR (Related Drugs)
          if (widget.relatedDrugs != null &&
              widget.relatedDrugs!.isNotEmpty) ...[
            const Text(
              "Muadil İlaçlar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (_isRelatedDrugsExpanded
                          ? widget.relatedDrugs!
                          : widget.relatedDrugs!.take(5))
                      .map((drug) {
                        return Chip(
                          label: Text(
                            drug.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          side: BorderSide.none,
                        );
                      })
                      .toList(),
            ),
            if (widget.relatedDrugs!.length > 5)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRelatedDrugsExpanded = !_isRelatedDrugsExpanded;
                  });
                },
                child: Text(
                  _isRelatedDrugsExpanded
                      ? "Daha Az Göster"
                      : "Tümünü Görüntüle (${widget.relatedDrugs!.length})",
                ),
              ),
          ],
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildImageSection({double? height}) {
    ImageProvider? imageProvider;

    if (widget.selectedImage != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(widget.selectedImage!.path);
      } else {
        imageProvider = FileImage(File(widget.selectedImage!.path));
      }
    } else if (widget.networkImageUrl != null) {
      // Backend URL düzeltmesi (gerekirse buraya eklenebilir ama dialogda hallediyoruz)
      imageProvider = NetworkImage(widget.networkImageUrl!);
    }

    return GestureDetector(
      onTap: widget.onPickImage,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          image:
              imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
        ),
        child:
            imageProvider == null
                ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Görsel Ekle", style: TextStyle(color: Colors.grey)),
                  ],
                )
                : Stack(
                  children: [
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildLocalDetailsTable() {
    return Column(
      children: [
        _buildDetailRow("Grup", widget.groupCtrl),
        _buildDetailRow("Firma", widget.firmCtrl),
        _buildDetailRow("Hayvan Türü", widget.animalCtrl),
        _buildDetailRow("Farmasötik Şekil", widget.shapeCtrl),
        _buildDetailRow("Etken Madde", widget.ingredientCtrl),
      ],
    );
  }

  Widget _buildDetailRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 110, // Etiket için sabit genişlik
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
