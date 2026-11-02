import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_card.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/app_picker_bottom_sheet.dart';
import '../../domain/models/part_item.dart';
import '../../domain/models/picker_item.dart';
import '../providers/metadata_providers.dart';
import '../providers/parts_providers.dart';

/// Stitch Screens 13 & 14: Add & Edit Spare Part (መለዋወጫ መመዝገብ / ማስተካከል).
///
/// Features 6 structured card sections (Basic info, Image upload, Specs & Units,
/// Stock & Shelf locator, Dynamic margin calculator banner, Internal notes),
/// camera & gallery image picker, barcode scan trigger, and sticky bottom action.
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
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
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
      _unitController.text = part.unit ?? '';
      _quantityController.text =
          part.cachedQuantity > 0 ? part.cachedQuantity.toStringAsFixed(0) : '';
      _purchasePriceController.text = part.purchasePrice != null
          ? part.purchasePrice!.toStringAsFixed(2)
          : '';
      _sellingPriceController.text = part.sellingPrice != null
          ? part.sellingPrice!.toStringAsFixed(2)
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
          _unitController.text.isNotEmpty ||
          _quantityController.text.isNotEmpty ||
          _purchasePriceController.text.isNotEmpty ||
          _sellingPriceController.text.isNotEmpty ||
          _customLocationController.text.isNotEmpty ||
          _sizeSpecsController.text.isNotEmpty ||
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
        _sizeSpecsController.text != (p.sizeSpecs ?? '') ||
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
              backgroundColor: context.colorScheme.error,
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
                  color: KeraColors.outlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: KeraColors.surfaceMuted,
                  child: Icon(Icons.camera_alt_rounded, color: KeraColors.actionBlue),
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
                  backgroundColor: KeraColors.surfaceMuted,
                  child: Icon(Icons.photo_library_rounded, color: KeraColors.actionBlue),
                ),
                title: Text(l10n.chooseFromGallery, style: KeraTypography.titleSmall()),
                subtitle: const Text('ከስልክ ማዕከለ-ስዕላት ምረጥ'),
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
              if (_photoLocalPath != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: KeraColors.stockOutBg,
                    child: Icon(Icons.delete_outline_rounded, color: KeraColors.error),
                  ),
                  title: Text(l10n.removePhoto,
                      style: KeraTypography.titleSmall(color: KeraColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoLocalPath = null);
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
              backgroundColor: KeraColors.actionBlue,
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
        name: _nameController.text,
        partNumber: _partNumberController.text,
        photoLocalPath: _photoLocalPath,
        brandId: _selectedBrand?.id,
        categoryId: _selectedCategory?.id,
        locationId: _selectedLocation?.id,
        customLocation: _customLocationController.text,
        description: _descriptionController.text,
        unit: _unitController.text,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        sizeSpecs: _sizeSpecsController.text,
        notes: _notesController.text,
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
        name: _nameController.text,
        partNumber: _partNumberController.text,
        photoLocalPath: _photoLocalPath,
        brandId: _selectedBrand?.id,
        categoryId: _selectedCategory?.id,
        locationId: _selectedLocation?.id,
        customLocation: _customLocationController.text,
        description: _descriptionController.text,
        unit: _unitController.text,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        sizeSpecs: _sizeSpecsController.text,
        notes: _notesController.text,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
        backgroundColor: KeraColors.surfaceCanvas,
        appBar: AppBar(
          backgroundColor: KeraColors.primaryNavy,
          foregroundColor: Colors.white,
          title: Text(
            isEditing ? l10n.editPart : l10n.addPart,
            style: KeraTypography.titleMedium(color: Colors.white).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _savePart,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
        body: _isLoading && !_isInitialized
            ? const Center(
                child: CircularProgressIndicator(color: KeraColors.actionBlue),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Section 1: Basic Information (Stitch Screen 13)
                    _buildSectionHeader('1. መሰረታዊ መረጃ (Basic Info)'),
                    KeraCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Part Name
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: KeraTypography.bodyMedium(),
                            decoration: InputDecoration(
                              labelText: l10n.partName,
                              hintText: l10n.partNameHint,
                              prefixIcon: const Icon(Icons.build_circle_outlined,
                                  color: KeraColors.actionBlue),
                              filled: true,
                              fillColor: KeraColors.surfaceMuted,
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                                borderSide: BorderSide(color: KeraColors.outlineBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // OEM Part Number
                          TextFormField(
                            controller: _partNumberController,
                            textCapitalization: TextCapitalization.characters,
                            style: KeraTypography.bodyMedium(),
                            decoration: InputDecoration(
                              labelText: l10n.partNumber,
                              hintText: l10n.partNumberHint,
                              prefixIcon: const Icon(Icons.numbers_rounded,
                                  color: KeraColors.actionBlue),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner_rounded,
                                    color: KeraColors.textSecondary),
                                tooltip: 'Scan part number',
                                onPressed: () {
                                  context.showSnackBar('የካሜራ ስካነር ዝግጁ ነው');
                                },
                              ),
                              filled: true,
                              fillColor: KeraColors.surfaceMuted,
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                                borderSide: BorderSide(color: KeraColors.outlineBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Brand & Category Selection Pickers
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickBrand,
                                  borderRadius: KeraRadii.borderInput,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: l10n.brand,
                                      prefixIcon: const Icon(Icons.directions_car_outlined,
                                          color: KeraColors.actionBlue),
                                      suffixIcon:
                                          const Icon(Icons.arrow_drop_down_rounded),
                                      filled: true,
                                      fillColor: KeraColors.surfaceMuted,
                                      border: const OutlineInputBorder(
                                        borderRadius: KeraRadii.borderInput,
                                        borderSide:
                                            BorderSide(color: KeraColors.outlineBorder),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedBrand?.name ?? '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: KeraTypography.bodyMedium(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickCategory,
                                  borderRadius: KeraRadii.borderInput,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: l10n.category,
                                      prefixIcon: const Icon(Icons.folder_open_outlined,
                                          color: KeraColors.actionBlue),
                                      suffixIcon:
                                          const Icon(Icons.arrow_drop_down_rounded),
                                      filled: true,
                                      fillColor: KeraColors.surfaceMuted,
                                      border: const OutlineInputBorder(
                                        borderRadius: KeraRadii.borderInput,
                                        borderSide:
                                            BorderSide(color: KeraColors.outlineBorder),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedCategory?.name ?? '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: KeraTypography.bodyMedium(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Product Image (Stitch Screen 13)
                    _buildSectionHeader('2. የዕቃው ፎቶ (Product Image)'),
                    KeraCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _showPhotoPickerSheet,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceMuted,
                                borderRadius: KeraRadii.borderCard,
                                border: Border.all(color: KeraColors.outlineBorder),
                                image: _photoLocalPath != null
                                    ? DecorationImage(
                                        image: FileImage(File(_photoLocalPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _photoLocalPath == null
                                  ? const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined,
                                            size: 28, color: KeraColors.actionBlue),
                                        SizedBox(height: 4),
                                        Text(
                                          'ፎቶ አንሳ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: KeraColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _photoLocalPath != null
                                      ? 'ፎቶው ተመርጧል'
                                      : 'ምስል በመጨመር ዕቃውን በቀላሉ ለይተው ይወቁ',
                                  style: KeraTypography.bodySmall(
                                    color: _photoLocalPath != null
                                        ? KeraColors.stockInText
                                        : KeraColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _showPhotoPickerSheet,
                                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                      label: Text(l10n.takePhoto),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                    if (_photoLocalPath != null) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            color: KeraColors.error),
                                        tooltip: l10n.removePhoto,
                                        onPressed: () =>
                                            setState(() => _photoLocalPath = null),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Specifications & Unit
                    _buildSectionHeader('3. ዝርዝር መግለጫ እና መለኪያ (Specs & Units)'),
                    KeraCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unit selection chips
                          Text('መለኪያ (Unit):',
                              style: KeraTypography.labelSmall(
                                  color: KeraColors.textSecondary)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: ['ቁራጭ (pcs)', 'ኪት (kit)', 'ካርቶን (box)', 'ሊትር (Ltr)', 'ሜትር (Mtr)'].map((u) {
                              final unitCode = u.split('(').last.replaceAll(')', '').trim();
                              final isSelected = _unitController.text.trim().toLowerCase() ==
                                  unitCode.toLowerCase();
                              return ChoiceChip(
                                label: Text(u, style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                selectedColor: KeraColors.actionBlue,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : KeraColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                                onSelected: (_) {
                                  setState(() => _unitController.text = unitCode);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          // Custom Unit text field
                          TextFormField(
                            controller: _unitController,
                            style: KeraTypography.bodyMedium(),
                            decoration: InputDecoration(
                              labelText: l10n.unit,
                              hintText: l10n.unitHint,
                              prefixIcon: const Icon(Icons.straighten_outlined,
                                  color: KeraColors.actionBlue),
                              filled: true,
                              fillColor: KeraColors.surfaceMuted,
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                                borderSide: BorderSide(color: KeraColors.outlineBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Size & Dimensions Specs
                          TextFormField(
                            controller: _sizeSpecsController,
                            style: KeraTypography.bodyMedium(),
                            decoration: InputDecoration(
                              labelText: l10n.sizeSpecs,
                              hintText: l10n.sizeSpecsHint,
                              prefixIcon: const Icon(Icons.tune_rounded,
                                  color: KeraColors.actionBlue),
                              filled: true,
                              fillColor: KeraColors.surfaceMuted,
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                                borderSide: BorderSide(color: KeraColors.outlineBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 2,
                            style: KeraTypography.bodyMedium(),
                            decoration: InputDecoration(
                              labelText: l10n.description,
                              hintText: l10n.descriptionHint,
                              prefixIcon: const Icon(Icons.notes_rounded,
                                  color: KeraColors.actionBlue),
                              filled: true,
                              fillColor: KeraColors.surfaceMuted,
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                                borderSide: BorderSide(color: KeraColors.outlineBorder),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Stock & Storage Location
                    _buildSectionHeader('4. ክምችት እና መደርደሪያ (Stock & Location)'),
                    KeraCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isEditing) ...[
                            // Quantity with Stepper
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    style: KeraTypography.bodyMedium(),
                                    decoration: InputDecoration(
                                      labelText: l10n.quantityInStock,
                                      hintText: '0',
                                      prefixIcon: const Icon(Icons.inventory_2_outlined,
                                          color: KeraColors.actionBlue),
                                      filled: true,
                                      fillColor: KeraColors.surfaceMuted,
                                      border: const OutlineInputBorder(
                                        borderRadius: KeraRadii.borderInput,
                                        borderSide:
                                            BorderSide(color: KeraColors.outlineBorder),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return null;
                                      final num = double.tryParse(val.trim());
                                      if (num == null || num < 0) {
                                        return l10n.negativeNumberError;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _stepQuantity(-1),
                                ),
                                IconButton.outlined(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _stepQuantity(1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Storage Shelf Picker
                          InkWell(
                            onTap: _pickLocation,
                            borderRadius: KeraRadii.borderInput,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.storageLocation,
                                prefixIcon: const Icon(Icons.shelves,
                                    color: KeraColors.actionBlue),
                                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                                filled: true,
                                fillColor: KeraColors.surfaceMuted,
                                border: const OutlineInputBorder(
                                  borderRadius: KeraRadii.borderInput,
                                  borderSide: BorderSide(color: KeraColors.outlineBorder),
                                ),
                              ),
                              child: Text(
                                _selectedLocation?.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KeraTypography.bodyMedium(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Custom Bin / Shelf Slot
                          TextFormField(
                            controller: _customLocationController,
                            style: KeraTypography.bodyMedium(),
                            decoration: InputDecoration(
                              labelText: l10n.customLocation,
                              hintText: l10n.customLocationHint,
                              prefixIcon: const Icon(Icons.place_outlined,
                                  color: KeraColors.actionBlue),
                              filled: true,
                              fillColor: KeraColors.surfaceMuted,
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                                borderSide: BorderSide(color: KeraColors.outlineBorder),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 5: Pricing & Dynamic Profit Margin Banner
                    _buildSectionHeader('5. የዋጋ ስሌት እና ትርፍ (Pricing & Valuation)'),
                    KeraCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _purchasePriceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  style: KeraTypography.bodyMedium(),
                                  decoration: InputDecoration(
                                    labelText: l10n.purchasePrice,
                                    prefixIcon: const Icon(Icons.shopping_bag_outlined,
                                        color: KeraColors.actionBlue),
                                    suffixText: 'ብር',
                                    filled: true,
                                    fillColor: KeraColors.surfaceMuted,
                                    border: const OutlineInputBorder(
                                      borderRadius: KeraRadii.borderInput,
                                      borderSide:
                                          BorderSide(color: KeraColors.outlineBorder),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return null;
                                    final num = double.tryParse(val.trim());
                                    if (num == null || num < 0) {
                                      return l10n.negativeNumberError;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _sellingPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  style: KeraTypography.bodyMedium(),
                                  decoration: InputDecoration(
                                    labelText: l10n.sellingPrice,
                                    prefixIcon: const Icon(Icons.monetization_on_outlined,
                                        color: KeraColors.actionBlue),
                                    suffixText: 'ብር',
                                    filled: true,
                                    fillColor: KeraColors.surfaceMuted,
                                    border: const OutlineInputBorder(
                                      borderRadius: KeraRadii.borderInput,
                                      borderSide:
                                          BorderSide(color: KeraColors.outlineBorder),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return null;
                                    final num = double.tryParse(val.trim());
                                    if (num == null || num < 0) {
                                      return l10n.negativeNumberError;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Live Margin Banner (Stitch Screen 13)
                          if (hasPriceInputs) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: profit >= 0
                                    ? KeraColors.stockInBg
                                    : KeraColors.stockOutBg,
                                borderRadius: KeraRadii.borderCard,
                                border: Border.all(
                                  color: profit >= 0
                                      ? KeraColors.stockInText.withValues(alpha: 0.3)
                                      : KeraColors.stockOutText.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    profit >= 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: profit >= 0
                                        ? KeraColors.stockInText
                                        : KeraColors.stockOutText,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      profit >= 0
                                          ? 'ትርፍ: +${profit.toStringAsFixed(0)} ብር (~${marginPct.toStringAsFixed(1)}% ትርፍ በአንድ ዕቃ)'
                                          : 'ኪሳራ: ${profit.toStringAsFixed(0)} ብር',
                                      style: KeraTypography.bodySmall(
                                        color: profit >= 0
                                            ? KeraColors.stockInText
                                            : KeraColors.stockOutText,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 6: Internal Notes
                    _buildSectionHeader('6. ተጨማሪ ማስታወሻ (Internal Notes)'),
                    KeraCard(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: KeraTypography.bodyMedium(),
                        decoration: InputDecoration(
                          labelText: l10n.notes,
                          hintText: l10n.notesHint,
                          prefixIcon: const Icon(Icons.edit_note_rounded,
                              color: KeraColors.actionBlue),
                          filled: true,
                          fillColor: KeraColors.surfaceMuted,
                          border: const OutlineInputBorder(
                            borderRadius: KeraRadii.borderInput,
                            borderSide: BorderSide(color: KeraColors.outlineBorder),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Action Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KeraColors.actionBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(
                            double.infinity, AppConstants.standardButtonHeight),
                        shape: const RoundedRectangleBorder(
                          borderRadius: KeraRadii.borderButton,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        l10n.save,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _isLoading ? null : _savePart,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: KeraTypography.labelLarge(color: KeraColors.primaryNavy).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
