import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/utils/text_utils.dart';
import 'package:mobile/core/widgets/dialogs/confirmation_dialog.dart';
import 'package:mobile/core/widgets/dialogs/discard_changes_dialog.dart';
import 'package:mobile/core/widgets/dialogs/info_dialog.dart';
import 'package:mobile/core/widgets/dialogs/warning_dialog.dart';
import 'package:mobile/features/products/domain/models/product.dart';
import 'package:mobile/features/products/presentation/providers/product_controller.dart';
import 'tabs/product_details_tab.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product; // null = EKLEME, !null = DÜZENLEME
  final String? initialBarcode;

  const ProductFormDialog({super.key, this.product, this.initialBarcode});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isLoading = false;

  // --- CONTROLLERS ---
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _criticalStockCtrl = TextEditingController();
  final _sktCtrl = TextEditingController();
  final _vatRateCtrl = TextEditingController(text: "0");
  final _notesCtrl = TextEditingController();

  // Detay Controllers
  final _groupCtrl = TextEditingController();
  final _firmCtrl = TextEditingController();
  final _animalCtrl = TextEditingController();
  final _shapeCtrl = TextEditingController();
  final _ingredientCtrl = TextEditingController();

  // --- STATE VARIABLES ---
  String? _normalizedName;
  XFile? _selectedImage;
  String? _networkImageUrl;
  String?
  _selectedRelativePath; // YENİ: Backend'e göndermek için (Relative Path)
  String _selectedUnit = 'PIECE';
  DateTime? _selectedDate;
  bool _showAdvancedSettings = false;
  late Future<List<dynamic>> _stockHistoryFuture;

  // Değişiklik Takibi İçin Orijinal Değerler
  Map<String, dynamic> _originalValues = {};

  final List<Map<String, String>> _unitTypes = [
    {'value': 'PIECE', 'label': 'Adet / Kutu'},
    {'value': 'WEIGHT', 'label': 'Ağırlık (Kg/Gr)'},
    {'value': 'VOLUME', 'label': 'Hacim (Lt/Ml)'},
  ];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.product != null;
    _tabController = TabController(length: isEditing ? 4 : 3, vsync: this);

    if (isEditing) {
      _initEditMode(widget.product!);
    } else {
      _initAddMode();
    }
  }

  void _initAddMode() {
    _barcodeCtrl.text = widget.initialBarcode ?? '';
    _criticalStockCtrl.text = "10";
    _stockHistoryFuture = Future.value([]);
    _captureOriginalValues(); // Boş değerleri kaydet
  }

  void _initEditMode(Product p) {
    _nameCtrl.text = p.name;
    _barcodeCtrl.text = p.barcode ?? '';
    _buyPriceCtrl.text = p.buyingPrice.toString();
    _sellPriceCtrl.text = p.sellingPrice.toString();
    _stockCtrl.text = p.stockQuantity.toString();
    _criticalStockCtrl.text = p.criticalStockLevel.toString();
    _vatRateCtrl.text = p.vatRate.toString();
    _selectedUnit = p.unitType;
    _networkImageUrl = p.fullImageUrl;
    _notesCtrl.text = p.localDetails?['user_notes_on_product'] ?? '';

    // Detayları Doldur
    final details = p.localDetails?['details'] ?? {};
    _groupCtrl.text = details['Grup'] ?? '';
    _firmCtrl.text = details['Firma'] ?? '';
    _shapeCtrl.text = details['Şekil'] ?? '';
    if (details['Hayvan'] is List)
      _animalCtrl.text = (details['Hayvan'] as List).join(', ');
    if (details['Etken Madde'] is List)
      _ingredientCtrl.text = (details['Etken Madde'] as List).join(', ');

    _stockHistoryFuture = ref
        .read(productControllerProvider)
        .getProductStocks(p.id);

    _captureOriginalValues();
  }

  // Orijinal değerleri kopyala (Değişiklik kontrolü için)
  void _captureOriginalValues() {
    _originalValues = {
      'name': _nameCtrl.text,
      'barcode': _barcodeCtrl.text,
      'buy': _buyPriceCtrl.text,
      'sell': _sellPriceCtrl.text,
      'stock': _stockCtrl.text,
      'critical': _criticalStockCtrl.text,
      'vat': _vatRateCtrl.text,
      'unit': _selectedUnit,
      'notes': _notesCtrl.text,
      'group': _groupCtrl.text,
      'image_url': _networkImageUrl,
      'selected_image_path': null, // Başlangıçta yeni seçilen resim yok
    };
  }

  // Değişiklik var mı kontrolü
  bool _hasChanges() {
    if (_selectedImage != null)
      return true; // Yeni resim seçildiyse kesin değişti
    if (_networkImageUrl != _originalValues['image_url'])
      return true; // Autocomplete ile resim değiştiyse

    return _nameCtrl.text != _originalValues['name'] ||
        _buyPriceCtrl.text != _originalValues['buy'] ||
        _sellPriceCtrl.text != _originalValues['sell'] ||
        _criticalStockCtrl.text != _originalValues['critical'] ||
        _vatRateCtrl.text != _originalValues['vat'] ||
        _selectedUnit != _originalValues['unit'] ||
        _notesCtrl.text != _originalValues['notes'] ||
        _groupCtrl.text != _originalValues['group'];
  }

  List<String> _getChangedFields() {
    List<String> changes = [];
    if (_nameCtrl.text != _originalValues['name']) changes.add("Ürün Adı");
    if (_buyPriceCtrl.text != _originalValues['buy'])
      changes.add("Alış Fiyatı");
    if (_sellPriceCtrl.text != _originalValues['sell'])
      changes.add("Satış Fiyatı");
    if (_selectedImage != null ||
        _networkImageUrl != _originalValues['image_url'])
      changes.add("Ürün Fotoğrafı");
    if (_criticalStockCtrl.text != _originalValues['critical'])
      changes.add("Kritik Stok");
    if (_notesCtrl.text != _originalValues['notes']) changes.add("Notlar");
    return changes;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _criticalStockCtrl.dispose();
    _sktCtrl.dispose();
    _vatRateCtrl.dispose();
    _notesCtrl.dispose();
    _groupCtrl.dispose();
    _firmCtrl.dispose();
    _animalCtrl.dispose();
    _shapeCtrl.dispose();
    _ingredientCtrl.dispose();
    super.dispose();
  }

  // --- RESİM & URL ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }

  // --- BUTON AKSİYONLARI ---

  void _handleCancel() {
    if (_hasChanges()) {
      showDialog(
        context: context,
        builder:
            (context) => DiscardChangesDialog(
              onDiscard: () {
                // İki kere pop: biri dialog, biri form
                Navigator.pop(context);
              },
            ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder:
          (context) => WarningDialog(
            title: "Ürünü Sil",
            content:
                "Bu ürünü silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
            confirmText: "Evet, Sil",
            onConfirm: _performDelete,
          ),
    );
  }

  void _performDelete() {
    setState(() => _isLoading = true);
    ref
        .read(productControllerProvider)
        .deleteProduct(
          id: widget.product!.id,
          onSuccess: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ürün silindi"),
                backgroundColor: AppColors.error,
              ),
            );
          },
          onError: (e) => _onError(e),
        );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final isEditing = widget.product != null;

    if (isEditing) {
      // DÜZENLEME MODU: Değişiklik onayı sor
      final changes = _getChangedFields();
      if (changes.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Değişiklik yapılmadı.")));
        return;
      }

      showDialog(
        context: context,
        builder:
            (context) => ConfirmationDialog(
              title: "Değişiklikleri Kaydet",
              changes: changes,
              onConfirm: _saveProduct,
            ),
      );
    } else {
      // EKLEME MODU: Direkt kaydet
      _saveProduct();
    }
  }

  Future<void> _saveProduct() async {
    setState(() => _isLoading = true);
    final controller = ref.read(productControllerProvider);
    final isEditing = widget.product != null;

    final localDetails = {
      "details": {
        "Grup": _groupCtrl.text,
        "Firma": _firmCtrl.text,
        "Şekil": _shapeCtrl.text,
        "Hayvan": _animalCtrl.text.split(',').map((e) => e.trim()).toList(),
        "Etken Madde":
            _ingredientCtrl.text.split(',').map((e) => e.trim()).toList(),
      },
      "user_notes_on_product": _notesCtrl.text,
    };

    try {
      if (isEditing) {
        await controller.updateProduct(
          id: widget.product!.id,
          updates: {
            "name": _nameCtrl.text,
            "normalized_name": _normalizedName ?? normalizeText(_nameCtrl.text),
            "buying_price": double.tryParse(_buyPriceCtrl.text) ?? 0,
            "selling_price": double.tryParse(_sellPriceCtrl.text) ?? 0,
            "critical_stock_level":
                double.tryParse(_criticalStockCtrl.text) ?? 10,
            "unit_type": _selectedUnit,
            "vat_rate": int.tryParse(_vatRateCtrl.text) ?? 0,
            "local_details": localDetails,
            // Eğer resim autocomplete'den geldiyse (File null ama URL değişmişse) bunu backend'e söylememiz gerekebilir
            // Ancak şu anki yapıda sadece File upload veya mevcut kalması destekleniyor olabilir.
            // Custom bir logic gerekirse backend güncellemesi isteyebilir.
            // Şimdilik sadece File upload'ı gönderiyoruz.
          },
          image: _selectedImage,
          onSuccess: () => _onSuccess("Ürün güncellendi"),
          onError: _onError,
        );

        debugPrint("normalized name: ${normalizeText(_nameCtrl.text)}");
      } else {
        await controller.addProduct(
          name: _nameCtrl.text,
          normalizedName: _normalizedName ?? normalizeText(_nameCtrl.text),
          barcode: _barcodeCtrl.text,
          buyingPrice: double.tryParse(_buyPriceCtrl.text) ?? 0,
          sellingPrice: double.tryParse(_sellPriceCtrl.text) ?? 0,
          initialStock: double.tryParse(_stockCtrl.text) ?? 0,
          expirationDate: _selectedDate,
          unitType: _selectedUnit,
          vatRate: int.tryParse(_vatRateCtrl.text) ?? 0,
          criticalStockLevel: double.tryParse(_criticalStockCtrl.text) ?? 10,
          localDetails: localDetails,
          image: _selectedImage,
          vetilacImagePath:
              _selectedImage == null ? _selectedRelativePath : null,
          onSuccess: () => _onSuccess("Ürün eklendi"),
          onError: _onError,
        );
        debugPrint("1. _selectedRelativePath: $_selectedRelativePath");
        debugPrint("2. _networkImageUrl: $_networkImageUrl");
      }
    } catch (e) {
      _onError(e.toString());
    }
  }

  void _onSuccess(String msg) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => InfoDialog(title: "Başarılı", content: msg),
    );
  }

  void _onError(String err) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: AppColors.error),
    );
  }

  // --- UI BÖLÜMÜ ---

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleCancel();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 850),
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Ürün Düzenle" : "Yeni Ürün Girişi",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _handleCancel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // TABS
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  const Tab(text: "Genel Bilgiler"),
                  const Tab(text: "Detaylar"),
                  const Tab(text: "Notlar"),
                  if (isEditing) const Tab(text: "Stok Geçmişi"),
                ],
              ),

              const Divider(height: 1),

              // CONTENT
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralTab(isEditing),
                      _buildDetailsTab(),
                      _buildNotesTab(),
                      if (isEditing) _buildStockHistoryTab(),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // FOOTER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing)
                      TextButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        label: const Text("Ürünü Sil"),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _handleCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text("Vazgeç"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                isEditing
                                    ? "Değişiklikleri Kaydet"
                                    : "Ürünü Kaydet",
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: GENEL BİLGİLER (RESİM & AUTOCOMPLETE BURADA) ---
  Widget _buildGeneralTab(bool isEditing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. RESİM ALANI (En Üstte)
          Center(child: _buildImageHeader()),
          const SizedBox(height: 24),

          // 2. AUTOCOMPLETE (Sadece Ekleme Modunda)
          if (!isEditing)
            _buildVetilacAutocomplete()
          else
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Ürün Adı",
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (v) => v!.isEmpty ? "Zorunlu" : null,
            ),

          const SizedBox(height: 16),

          // 3. FİYATLAR & BARKOD
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _barcodeCtrl,
                  readOnly: isEditing,
                  decoration: InputDecoration(
                    labelText: "Barkod",
                    prefixIcon: const Icon(Icons.qr_code),
                    fillColor: isEditing ? Colors.grey.shade100 : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Alış",
                          suffixText: "₺",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Satış",
                          suffixText: "₺",
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. STOK & DİĞER
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockCtrl,
                  readOnly: isEditing,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isEditing ? "Stok" : "Başlangıç Stok",
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    fillColor: isEditing ? Colors.grey.shade100 : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _criticalStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Kritik Sınır",
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                ),
              ),
            ],
          ),

          if (!isEditing) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _sktCtrl,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                labelText: "Son Kullanma Tarihi",
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
          ],

          // ADVANCED SETTINGS
          Center(
            child: TextButton.icon(
              onPressed:
                  () => setState(
                    () => _showAdvancedSettings = !_showAdvancedSettings,
                  ),
              icon: Icon(
                _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
              ),
              label: const Text("KDV ve Birim Ayarları"),
            ),
          ),

          if (_showAdvancedSettings) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: "Birim"),
                    items:
                        _unitTypes
                            .map(
                              (e) => DropdownMenuItem(
                                value: e['value'],
                                child: Text(e['label']!),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vatRateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "KDV (%)"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- RESİM HEADER WIDGETI ---
  Widget _buildImageHeader() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(File(_selectedImage!.path));
    } else if (_networkImageUrl != null) {
      imageProvider = NetworkImage(_networkImageUrl!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
              image:
                  imageProvider != null
                      ? DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.contain,
                      )
                      : null,
            ),
            child:
                imageProvider == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fotoğraf Ekle",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                    : Stack(
                      children: [
                        Positioned(
                          right: 8,
                          bottom: 8,
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
        ],
      ),
    );
  }

  // --- GELİŞMİŞ AUTOCOMPLETE WIDGETI (RawAutocomplete) ---
  Widget _buildVetilacAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Map<String, dynamic>>(
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.length < 2) return [];
            return await ref
                .read(productControllerProvider)
                .searchVetilac(textEditingValue.text);
          },
          displayStringForOption: (option) => option['raw_name'],
          onSelected: (selection) async {
            _nameCtrl.text = selection['raw_name'];
            _normalizedName = selection['normalized_name'];
            // 1. Ham veriyi (Relative) sakla
            _selectedRelativePath = selection['image_path'];

            _networkImageUrl =
                selection['image_path'] != null
                    ? _getImageUrl(selection['image_path'])
                    : selection['full_image_url'];
            setState(() {});

            // Detayları çek
            final data = await ref
                .read(productControllerProvider)
                .getVetilacDetails(selection['id']);
            if (data != null && data['details'] != null) {
              final d = data['details'];
              _groupCtrl.text = d['Grup'] ?? '';
              _firmCtrl.text = d['Firma'] ?? '';
              _shapeCtrl.text = d['Şekil'] ?? '';
              if (d['Hayvan'] is List)
                _animalCtrl.text = (d['Hayvan'] as List).join(', ');
              if (d['Etken Madde'] is List)
                _ingredientCtrl.text = (d['Etken Madde'] as List).join(', ');
            }
          },
          fieldViewBuilder: (
            context,
            textController,
            focusNode,
            onFieldSubmitted,
          ) {
            // State ile senkronizasyon
            if (_nameCtrl.text.isNotEmpty && textController.text.isEmpty) {
              textController.text = _nameCtrl.text;
            }
            textController.addListener(() {
              _nameCtrl.text = textController.text;
            });

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: "İlaç Adı Ara",
                hintText: "Örn: Amoklavin...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon:
                    _isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : null,
                filled: true,
                fillColor: AppColors.textHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    separatorBuilder:
                        (ctx, index) => const Divider(height: 1, indent: 60),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);

                      // Resim URL'ini hazırla
                      String? imgUrl;
                      if (option['image_path'] != null) {
                        imgUrl = _getImageUrl(option['image_path']);
                      } else {
                        imgUrl = option['full_image_url'];
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child:
                              imgUrl != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (c, u) => const Icon(
                                            Icons.image,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                      errorWidget:
                                          (c, u, e) => const Icon(
                                            Icons.broken_image,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.medication,
                                    color: AppColors.primary,
                                  ),
                        ),
                        title: Text(
                          option['raw_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          option['barcode'] ?? 'Barkod Yok',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- DİĞER TABLAR (AYNI KALDI) ---
  Widget _buildDetailsTab() {
    return ProductDetailsTab(
      groupCtrl: _groupCtrl,
      firmCtrl: _firmCtrl,
      animalCtrl: _animalCtrl,
      shapeCtrl: _shapeCtrl,
      ingredientCtrl: _ingredientCtrl,
      prospectus: widget.product?.prospectus,
      relatedDrugs: widget.product?.relatedDrugs,
      selectedImage: _selectedImage,
      networkImageUrl: _networkImageUrl,
      onPickImage: _pickImage,
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: _notesCtrl,
        maxLines: 20,
        decoration: const InputDecoration(
          hintText: "Ürünle ilgili özel notlar...",
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStockHistoryTab() {
    return FutureBuilder<List<dynamic>>(
      future: _stockHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text("Hareket bulunamadı."));
        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: AppColors.primary),
              ),
              title: Text(
                "${item['quantity'] > 0 ? '+' : ''}${item['quantity']} Adet",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat(
                  'dd.MM.yyyy HH:mm',
                ).format(DateTime.parse(item['created_at'])),
              ),
              trailing: Text(
                item['type'] ?? 'Hareket',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  void _selectDate(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          _selectedDate = pickedDate;
          _sktCtrl.text = DateFormat('dd.MM.yyyy').format(pickedDate);
        });
      }
    });
  }
}
