import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/app_picker_bottom_sheet.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../domain/models/part_item.dart';
import '../../domain/models/picker_item.dart';
import '../providers/metadata_providers.dart';
import '../providers/parts_providers.dart';

/// Screen 3: Add / Edit Spare Part (3 Add spare part.png).
///
/// Designed to match the Owner App mockup:
/// - Deep Navy top header (#0C2340) with back arrow and title
/// - Light canvas background (#F4F7FB)
/// - Dashed/styled photo picker container with camera icon
/// - Helpful tip banner: "ሁሉም መስኮች አማራጭ ናቸው — ባዶ ትተው ማስቀመጥ ይችላሉ።"
/// - Clean 2-column input fields for Brand/Category, Unit/Quantity, Cost/Selling Price, Location/Note
/// - Live profit margin card (+350 ETB · 29.2% ትርፍ)
/// - Sticky bottom orange button (#F58220) "አስቀምጥ"
class PartFormScreen extends ConsumerStatefulWidget {
  final String? partId;

  const PartFormScreen({
    super.key,
    this.partId,
  });

  @override
  ConsumerState<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends ConsumerState<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController(text: 'ፍሬ (Pcs)');
  final _quantityController = TextEditingController(text: '1');
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _customLocationController = TextEditingController();
  final _sizeSpecsController = TextEditingController();
  final _notesController = TextEditingController();

  // Selection states
  String? _photoLocalPath;
  PickerItem? _selectedBrand;
  PickerItem? _selectedCategory;
  PickerItem? _selectedLocation;

  bool _isLoading = false;
  bool _isInitialized = false;
  PartItem? _initialPart;

  bool get isEditing => widget.partId != null;

  @override
  void initState() {
    super.initState();
    _purchasePriceController.addListener(_onPriceChanged);
    _sellingPriceController.addListener(_onPriceChanged);

    if (isEditing) {
      _loadExistingPart();
    } else {
      _isInitialized = true;
    }
  }

  void _onPriceChanged() {
    setState(() {});
  }

  Future<void> _loadExistingPart() async {
    setState(() => _isLoading = true);
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(partsRepositoryProvider);
    final result = await repo.getPartById(ownerId: ownerId, id: widget.partId!);

    if (!mounted) return;

    if (result.isSuccess && result.valueOrNull != null) {
      final part = result.valueOrNull!;
      _initialPart = part;
      _nameController.text = part.name ?? '';
      _partNumberController.text = part.partNumber ?? '';
      _descriptionController.text = part.description ?? '';
      _unitController.text = part.unit?.isNotEmpty == true ? part.unit! : 'ፍሬ (Pcs)';
      _quantityController.text =
          part.cachedQuantity > 0 ? part.cachedQuantity.toStringAsFixed(0) : '0';
      _purchasePriceController.text = part.purchasePrice != null
          ? part.purchasePrice!.toStringAsFixed(0)
          : '';
      _sellingPriceController.text = part.sellingPrice != null
          ? part.sellingPrice!.toStringAsFixed(0)
          : '';
      _customLocationController.text = part.customLocation ?? '';
      _sizeSpecsController.text = part.sizeSpecs ?? '';
      _notesController.text = part.notes ?? '';
      _photoLocalPath = part.photoLocalPath;

      // Resolve brand, category, location labels if present
      if (part.brandId != null) {
        final brands = await ref.read(brandsRepositoryProvider).getBrands(ownerId);
        final found = brands.valueOrNull?.where((b) => b.id == part.brandId).firstOrNull;
        if (found != null) {
          _selectedBrand = found.toPickerItem();
        }
      }
      if (part.categoryId != null) {
        final cats =
            await ref.read(categoriesRepositoryProvider).getCategories(ownerId);
        final found = cats.valueOrNull?.where((c) => c.id == part.categoryId).firstOrNull;
        if (found != null) {
          _selectedCategory = found.toPickerItem();
        }
      }
      if (part.locationId != null) {
        final locs =
            await ref.read(locationsRepositoryProvider).getLocations(ownerId);
        final found = locs.valueOrNull?.where((l) => l.id == part.locationId).firstOrNull;
        if (found != null) {
          _selectedLocation = found.toPickerItem();
        }
      }
    }

    setState(() {
      _isLoading = false;
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _purchasePriceController.removeListener(_onPriceChanged);
    _sellingPriceController.removeListener(_onPriceChanged);
    _nameController.dispose();
    _partNumberController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _customLocationController.dispose();
    _sizeSpecsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    if (!_isInitialized) return false;
    if (_initialPart == null) {
      return _nameController.text.isNotEmpty ||
          _partNumberController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _purchasePriceController.text.isNotEmpty ||
          _sellingPriceController.text.isNotEmpty ||
          _customLocationController.text.isNotEmpty ||
          _notesController.text.isNotEmpty ||
          _photoLocalPath != null ||
          _selectedBrand != null ||
          _selectedCategory != null ||
          _selectedLocation != null;
    }

    final p = _initialPart!;
    return _nameController.text != (p.name ?? '') ||
        _partNumberController.text != (p.partNumber ?? '') ||
        _descriptionController.text != (p.description ?? '') ||
        _unitController.text != (p.unit ?? '') ||
        _customLocationController.text != (p.customLocation ?? '') ||
        _notesController.text != (p.notes ?? '') ||
        _photoLocalPath != p.photoLocalPath ||
        _selectedBrand?.id != p.brandId ||
        _selectedCategory?.id != p.categoryId ||
        _selectedLocation?.id != p.locationId;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) return true;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepEditing),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _showPhotoPickerSheet() async {
    final l10n = context.l10n;
    final imageService = ref.read(imageServiceProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: KeraRadii.borderSheet),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF0C2340)),
                ),
                title: Text(l10n.takePhoto, style: KeraTypography.titleSmall()),
                subtitle: const Text('በካሜራ ፎቶ አንሳ'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final photo = await imageService.captureOrPickPhoto(
                    source: ImageSource.camera,
                  );
                  if (photo != null && mounted) {
                    setState(() => _photoLocalPath = photo.fullPath);
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFF0C2340)),
                ),
                title: const Text('ከስልክ ማዕከለ-ስዕላት ምረጥ'),
                subtitle: const Text('ፎቶ ከስልክ ምረጥ'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final photo = await imageService.captureOrPickPhoto(
                    source: ImageSource.gallery,
                  );
                  if (photo != null && mounted) {
                    setState(() => _photoLocalPath = photo.fullPath);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBrand() async {
    final l10n = context.l10n;
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(brandsRepositoryProvider);
    final brandsRes = await repo.getBrands(ownerId);
    final items =
        brandsRes.valueOrNull?.map((b) => b.toPickerItem()).toList() ?? [];

    if (!mounted) return;

    final picked = await AppPickerBottomSheet.show(
      context: context,
      title: l10n.selectBrand,
      searchHint: l10n.searchBrands,
      items: items,
      selectedId: _selectedBrand?.id,
      onQuickAdd: () async {
        final name = await _promptQuickAddName(l10n.addBrand, l10n.brandName);
        if (name == null || name.trim().isEmpty) return null;
        final res = await repo.createBrand(ownerId: ownerId, name: name.trim());
        return res.valueOrNull?.toPickerItem();
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedBrand = picked);
    }
  }

  Future<void> _pickCategory() async {
    final l10n = context.l10n;
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(categoriesRepositoryProvider);
    final catsRes = await repo.getCategories(ownerId);
    final items =
        catsRes.valueOrNull?.map((c) => c.toPickerItem()).toList() ?? [];

    if (!mounted) return;

    final picked = await AppPickerBottomSheet.show(
      context: context,
      title: l10n.selectCategory,
      searchHint: l10n.searchCategories,
      items: items,
      selectedId: _selectedCategory?.id,
      onQuickAdd: () async {
        final name = await _promptQuickAddName(l10n.addCategory, l10n.categoryName);
        if (name == null || name.trim().isEmpty) return null;
        final res = await repo.createCategory(ownerId: ownerId, name: name.trim());
        return res.valueOrNull?.toPickerItem();
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedCategory = picked);
    }
  }

  Future<void> _pickLocation() async {
    final l10n = context.l10n;
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(locationsRepositoryProvider);
    final locsRes = await repo.getLocations(ownerId);
    final items =
        locsRes.valueOrNull?.map((l) => l.toPickerItem()).toList() ?? [];

    if (!mounted) return;

    final picked = await AppPickerBottomSheet.show(
      context: context,
      title: l10n.selectLocation,
      searchHint: l10n.searchLocations,
      items: items,
      selectedId: _selectedLocation?.id,
      onQuickAdd: () async {
        final name = await _promptQuickAddName(l10n.addLocation, l10n.locationName);
        if (name == null || name.trim().isEmpty) return null;
        final res = await repo.createLocation(ownerId: ownerId, name: name.trim());
        return res.valueOrNull?.toPickerItem();
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedLocation = picked);
    }
  }

  Future<String?> _promptQuickAddName(String title, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: KeraTypography.titleSmall()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(borderRadius: KeraRadii.borderInput),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C2340),
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(partsRepositoryProvider);
    final l10n = context.l10n;

    // Parse numeric fields safely
    final purchasePrice = _purchasePriceController.text.trim().isNotEmpty
        ? double.tryParse(_purchasePriceController.text.trim())
        : null;
    final sellingPrice = _sellingPriceController.text.trim().isNotEmpty
        ? double.tryParse(_sellingPriceController.text.trim())
        : null;
    final initialQuantity = _quantityController.text.trim().isNotEmpty
        ? double.tryParse(_quantityController.text.trim())
        : null;

    if (isEditing) {
      final result = await repo.updatePart(
        ownerId: ownerId,
        id: widget.partId!,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        partNumber: _partNumberController.text.trim().isEmpty ? null : _partNumberController.text.trim(),
        photoLocalPath: _photoLocalPath,
        brandId: _selectedBrand?.id,
        categoryId: _selectedCategory?.id,
        locationId: _selectedLocation?.id,
        customLocation: _customLocationController.text.trim(),
        description: _descriptionController.text.trim(),
        unit: _unitController.text.trim(),
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        sizeSpecs: _sizeSpecsController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        context.showSnackBar(l10n.partSavedSuccess);
        Navigator.of(context).pop(true);
      } else {
        context.showSnackBar(
          result.failureOrNull?.message ?? 'Error saving part',
          isError: true,
        );
      }
    } else {
      final result = await repo.createPart(
        ownerId: ownerId,
        name: _nameController.text.trim().isEmpty ? 'ዕቃ' : _nameController.text.trim(),
        partNumber: _partNumberController.text.trim(),
        photoLocalPath: _photoLocalPath,
        brandId: _selectedBrand?.id,
        categoryId: _selectedCategory?.id,
        locationId: _selectedLocation?.id,
        customLocation: _customLocationController.text.trim(),
        description: _descriptionController.text.trim(),
        unit: _unitController.text.trim(),
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        sizeSpecs: _sizeSpecsController.text.trim(),
        notes: _notesController.text.trim(),
        initialQuantity: initialQuantity,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        context.showSnackBar(l10n.partSavedSuccess);
        Navigator.of(context).pop(true);
      } else {
        context.showSnackBar(
          result.failureOrNull?.message ?? 'Error creating part',
          isError: true,
        );
      }
    }
  }

  void _stepQuantity(double delta) {
    final current = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final updated = (current + delta).clamp(0.0, 999999.0);
    setState(() {
      _quantityController.text = updated.toStringAsFixed(0);
    });
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    final isDark = context.isDark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        fontSize: 13,
      ),
      filled: true,
      fillColor: context.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF58220), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cost = double.tryParse(_purchasePriceController.text.trim());
    final sell = double.tryParse(_sellingPriceController.text.trim());
    final hasPriceInputs = sell != null && sell > 0;
    final profit = hasPriceInputs ? (sell - (cost ?? 0.0)) : 0.0;
    final marginPct = (hasPriceInputs && cost != null && cost > 0)
        ? ((profit / cost) * 100)
        : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF071322) : const Color(0xFF0C2340),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            isEditing
                ? context.tr('ዕቃ ማስተካከል', 'Edit Spare Part')
                : context.tr('ዕቃ መጨመር', 'Add Spare Part'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: _isLoading && !_isInitialized
            ? KeraLoadingView(
                message: context.tr('የዕቃ መረጃ በመጫን ላይ...', 'Loading part details...'),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // 1. Photo Picker Dashed/Rounded Container (3 Add spare part.png)
                    GestureDetector(
                      onTap: _showPhotoPickerSheet,
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? const Color(0x22000000) : const Color(0x060C2340),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _photoLocalPath != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_photoLocalPath!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                        onPressed: () => setState(() => _photoLocalPath = null),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: isDark ? Colors.white : const Color(0xFF0C2340),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('ፎቶ ጨምር (አማራጭ)', 'Add Photo (Optional)'),
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    context.tr('ካሜራ ወይም ከስልክ ማዕከለ-ስዕላት ምረጥ', 'Take photo or choose from gallery'),
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Helper Hint Notice (3 Add spare part.png)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(
                                'ሁሉም መስኮች አማራጭ ናቸው — ባዶ ትተው ማስቀመጥ ይችላሉ።',
                                'All fields are optional — you can save with partial information.',
                              ),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Name field
                    _buildFieldLabel(context.tr('የዕቃ ስም', 'Part Name'), isRequired: false),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: context.textPrimaryColor),
                      decoration: _inputDecoration(
                        hintText: context.tr('ምሳሌ፦ ዘይት ፊልተር (Oil Filter)', 'e.g. Oil Filter / Fuel Pump'),
                        prefixIcon: Icon(Icons.build_circle_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Part Number field with scanner
                    _buildFieldLabel(context.tr('የዕቃ ቁጥር (Part No.)', 'Part Number (OEM No.)')),
                    TextFormField(
                      controller: _partNumberController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: context.textPrimaryColor),
                      decoration: _inputDecoration(
                        hintText: 'ምሳሌ፦ 1R-0716 / LF691A',
                        prefixIcon: Icon(Icons.tag_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFF58220)),
                          onPressed: () {
                            context.showSnackBar(context.tr('የባርኮድ ስካነር ዝግጁ ነው', 'Barcode scanner ready'));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Two-column: Brand & Category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('ብራንድ (Brand)', 'Brand')),
                              InkWell(
                                onTap: _pickBrand,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderColor),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedBrand?.name ?? context.tr('ምረጥ...', 'Select...'),
                                          style: TextStyle(
                                            color: _selectedBrand != null
                                                ? context.textPrimaryColor
                                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                            fontSize: 13,
                                            fontWeight: _selectedBrand != null ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('ምድብ (Category)', 'Category')),
                              InkWell(
                                onTap: _pickCategory,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderColor),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedCategory?.name ?? context.tr('ምረጥ...', 'Select...'),
                                          style: TextStyle(
                                            color: _selectedCategory != null
                                                ? context.textPrimaryColor
                                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                            fontSize: 13,
                                            fontWeight: _selectedCategory != null ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 6. Two-column: Unit & Quantity
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('መለኪያ (Unit)', 'Unit')),
                              TextFormField(
                                controller: _unitController,
                                style: TextStyle(color: context.textPrimaryColor),
                                decoration: _inputDecoration(
                                  hintText: context.tr('ፍሬ (Pcs)', 'Pcs / Sets'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('ብዛት (Quantity)', 'Quantity')),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => _stepQuantity(-1),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 38,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: context.cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: context.borderColor),
                                      ),
                                      child: Icon(Icons.remove_rounded, size: 18, color: context.textPrimaryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: context.textPrimaryColor),
                                      decoration: _inputDecoration(hintText: '0'),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _stepQuantity(1),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 38,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0C2340),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 7. Two-column: Cost Price & Selling Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('የመግዣ ዋጋ (Cost Price)', 'Cost Price')),
                              TextFormField(
                                controller: _purchasePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: context.textPrimaryColor),
                                decoration: _inputDecoration(hintText: '850', suffixText: 'ETB'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('የመሸጫ ዋጋ (Selling Price)', 'Selling Price')),
                              TextFormField(
                                controller: _sellingPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: context.textPrimaryColor),
                                decoration: _inputDecoration(hintText: '1,200', suffixText: 'ETB'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 8. Live Margin / Profit Card (3 Add spare part.png)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: profit >= 0
                            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                            : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: profit >= 0
                              ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                profit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: profit >= 0
                                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                    : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('ትርፍ በአንድ ፍሬ (Profit)', 'Profit per unit'),
                                style: TextStyle(
                                  color: profit >= 0
                                      ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                      : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            profit >= 0
                                ? '+${profit.toStringAsFixed(0)} ETB (${marginPct.toStringAsFixed(1)}% ${context.tr("ትርፍ", "profit")})'
                                : '${profit.toStringAsFixed(0)} ETB',
                            style: TextStyle(
                              color: profit >= 0
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                  : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 9. Two-column: Location & Note
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('መደርደሪያ / ቦታ (Location)', 'Shelf / Location')),
                              TextFormField(
                                controller: _customLocationController,
                                style: TextStyle(color: context.textPrimaryColor),
                                decoration: _inputDecoration(
                                  hintText: 'ምሳሌ፦ A-12',
                                  prefixIcon: Icon(Icons.shelves, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    onPressed: () async {
                                      await _pickLocation();
                                      if (_selectedLocation != null) {
                                        _customLocationController.text = _selectedLocation!.name;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context.tr('ማስታወሻ (Note)', 'Note')),
                              TextFormField(
                                controller: _notesController,
                                style: TextStyle(color: context.textPrimaryColor),
                                decoration: _inputDecoration(
                                  hintText: context.tr('ምሳሌ፦ ኦሪጅናል CAT', 'e.g. OEM Heavy Duty'),
                                  prefixIcon: Icon(Icons.note_alt_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border(top: BorderSide(color: context.borderColor)),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _savePart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF58220),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const KeraLoadingIndicator.small(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('አስቀምጥ', 'Save Part'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
