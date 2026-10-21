import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/app_picker_bottom_sheet.dart';
import '../../domain/models/part_item.dart';
import '../../domain/models/picker_item.dart';
import '../providers/metadata_providers.dart';
import '../providers/parts_providers.dart';

/// Screen for creating or editing a spare part.
/// ALL catalog fields are completely optional per requirements.
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
    if (isEditing) {
      _loadExistingPart();
    } else {
      _isInitialized = true;
    }
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
    final colorScheme = context.colorScheme;
    final imageService = ref.read(imageServiceProvider);

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(l10n.takePhoto),
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
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.chooseFromGallery),
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
                leading: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                title: Text(l10n.removePhoto, style: TextStyle(color: colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photoLocalPath = null);
                },
              ),
          ],
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
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

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
        appBar: AppBar(
          title: Text(isEditing ? l10n.editPart : l10n.addPart),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _savePart,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ],
        ),
        body: _isLoading && !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Photo Upload Card
                    Center(
                      child: GestureDetector(
                        onTap: _showPhotoPickerSheet,
                        child: Stack(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 1.5,
                                ),
                                image: _photoLocalPath != null
                                    ? DecorationImage(
                                        image: FileImage(File(_photoLocalPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _photoLocalPath == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 36,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.takePhoto,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            if (_photoLocalPath != null)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colorScheme.primary,
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Basic Information
                    Text(
                      '1. መሰረታዊ መረጃ (Basic Info)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Part Name (Optional)
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.partName,
                        hintText: l10n.partNameHint,
                        prefixIcon: const Icon(Icons.build_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Part Number (Optional)
                    TextFormField(
                      controller: _partNumberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.partNumber,
                        hintText: l10n.partNumberHint,
                        prefixIcon: const Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Brand & Category Selectors
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickBrand,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.brand,
                                prefixIcon: const Icon(Icons.directions_car_outlined),
                                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                              ),
                              child: Text(
                                _selectedBrand?.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickCategory,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.category,
                                prefixIcon: const Icon(Icons.folder_open_outlined),
                                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                              ),
                              child: Text(
                                _selectedCategory?.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Stock & Pricing
                    Text(
                      '2. ክምችት እና ዋጋ (Stock & Pricing)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quantity in Stock (Initial quantity on create)
                    if (!isEditing) ...[
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.quantityInStock,
                          hintText: '0',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
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
                      const SizedBox(height: 12),
                    ],

                    // Unit
                    TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: l10n.unit,
                        hintText: l10n.unitHint,
                        prefixIcon: const Icon(Icons.straighten_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Purchase Price & Selling Price
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.purchasePrice,
                              prefixIcon: const Icon(Icons.shopping_bag_outlined),
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
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.sellingPrice,
                              prefixIcon: const Icon(Icons.monetization_on_outlined),
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
                    const SizedBox(height: 24),

                    // Section 3: Storage Location
                    Text(
                      '3. የማስቀመጫ ቦታ (Storage Location)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: _pickLocation,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.storageLocation,
                          prefixIcon: const Icon(Icons.shelves),
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                        child: Text(
                          _selectedLocation?.name ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _customLocationController,
                      decoration: InputDecoration(
                        labelText: l10n.customLocation,
                        hintText: l10n.customLocationHint,
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Specifications & Notes
                    Text(
                      '4. ተጨማሪ ዝርዝሮች (Specs & Notes)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _sizeSpecsController,
                      decoration: InputDecoration(
                        labelText: l10n.sizeSpecs,
                        hintText: l10n.sizeSpecsHint,
                        prefixIcon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        hintText: l10n.descriptionHint,
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.notes,
                        hintText: l10n.notesHint,
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Action Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppConstants.standardButtonHeight),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        l10n.save,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _isLoading ? null : _savePart,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
