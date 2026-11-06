import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/context_extensions.dart';
import '../widgets/mobile_components.dart';

/// Debug-only gallery showcasing all native mobile components and StatusBadge variants.
class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends ConsumerState<ComponentGalleryScreen> {
  final _searchController = TextEditingController();
  int _selectedChip = 0;
  double _stepperVal = 3.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Debug only')),
      );
    }

    final isDark = context.isDark;
    final isAmharic = context.isAmharic;

    return PageScaffold(
      appBar: AppBar(
        title: const Text('Component Gallery'),
        backgroundColor: context.cardBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () {
              ref.read(themeModeControllerProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
          IconButton(
            tooltip: 'Toggle Language',
            icon: const Icon(Icons.language_rounded),
            onPressed: () {
              ref.read(localeControllerProvider.notifier).setLocale(
                    Locale(isAmharic ? 'en' : 'am'),
                  );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: StatusBadge Matrix
          const SectionHeader(title: 'StatusBadge Variants (2-Color System)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge.inStock(quantity: 42, unit: 'pcs'),
              StatusBadge.lowStock(quantity: 3),
              StatusBadge.outOfStock(),
              StatusBadge.synced(),
              StatusBadge.syncing(),
              StatusBadge.pending(count: 7),
              StatusBadge.failed(),
              StatusBadge.conflict(),
              StatusBadge.offline(),
              StatusBadge.active(),
              StatusBadge.suspended(),
            ],
          ),
          const SizedBox(height: 24),

          // Section: Buttons
          const SectionHeader(title: 'Buttons'),
          PrimaryButton(
            label: 'Primary Button',
            icon: Icons.check_circle_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          const PrimaryButton(
            label: 'Loading Button',
            isLoading: true,
            progressValue: 0.75,
            onPressed: null,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Secondary Outline Button',
            icon: Icons.share_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          Center(
            child: TextActionButton(
              label: 'Text Action Button →',
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 24),

          // Section: Cards & Summaries
          const SectionHeader(title: 'Cards & Metrics'),
          SummaryCard(
            title: "Today's Sales Revenue",
            mainAmount: '84,520.00 ETB',
            subtitle: '18 transactions · 94.2% margin',
            trailing: StatusBadge.synced(),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: KpiCard(
                  label: 'In Stock SKUs',
                  value: '1,420',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: 'Low Stock Alerts',
                  value: '14',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StockCard(
            currentQuantity: 18,
            minQuantity: 5,
            unit: 'Pcs',
            onStockIn: () {},
            onStockOut: () {},
          ),
          const SizedBox(height: 24),

          // Section: List Items
          const SectionHeader(title: 'Tiles & Rows'),
          PartTile(
            title: 'Caterpillar 320D Hydraulic Oil Filter Element High Pressure',
            partNumber: '1R-0716',
            shelfLocation: 'Shelf B-12',
            price: 2450.00,
            quantity: 12,
            unit: 'Pcs',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          PartTile(
            title: 'Doosan Excavator Air Filter Inner & Outer Set Heavy Duty',
            partNumber: '400504-00075',
            shelfLocation: 'Zone A',
            price: 4800.00,
            quantity: 2,
            minQuantity: 5,
            unit: 'Sets',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          SaleTile(
            receiptNumber: 'REC-2026-0841',
            itemCount: 4,
            totalAmount: 14200.00,
            dateText: 'Today 10:45 AM',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          MovementTile(
            title: 'Purchase Restock',
            quantityChange: 20,
            dateText: 'Today 09:15 AM',
            note: 'Invoice #PO-9821',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          OwnerTile(
            businessName: 'Selam Spare Parts & Logistics',
            ownerName: 'Abebe Kebede',
            phoneNumber: '+251 91 123 4567',
            partsCount: 840,
            isActive: true,
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Section: Controls & Pickers
          const SectionHeader(title: 'Controls & Inputs'),
          SearchField(
            controller: _searchController,
            hintText: 'Search parts, brands, shelf...',
          ),
          const SizedBox(height: 12),
          FilterChipRow(
            labels: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
            selectedIndex: _selectedChip,
            onSelected: (i) => setState(() => _selectedChip = i),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quantity Stepper:', style: TextStyle(color: context.textPrimaryColor)),
              QuantityStepper(
                value: _stepperVal,
                min: 1,
                max: 50,
                onChanged: (v) => setState(() => _stepperVal = v),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section: Layout & Helpers
          const SectionHeader(title: 'Layout & Status Helpers'),
          const DateGroupHeader(dateText: 'Monday, Nov 6, 2026', rightText: '4 Sales'),
          const SizedBox(height: 8),
          const OfflineBanner(),
          const SizedBox(height: 12),
          const SkeletonBox(width: double.infinity, height: 48),
          const SizedBox(height: 24),

          // Section: Settings Group
          SettingsGroup(
            title: 'Preferences',
            children: [
              SettingsTile(
                icon: Icons.store_rounded,
                title: 'Shop Profile',
                subtitle: 'Manage shop name and contact info',
                onTap: () {},
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.security_rounded,
                title: 'Security & App Lock',
                subtitle: 'PIN code and biometric security',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section: BottomNav Demonstration
          const SectionHeader(title: 'BottomNav Preview (4 Tabs + Raised Sell)'),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: BottomNav(
              currentIndex: 0,
              onTabSelected: (_) {},
              onSellPressed: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
