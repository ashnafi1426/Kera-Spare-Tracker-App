import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/parts_providers.dart';

/// Main container screen with bottom navigation for Inventory, Sales, Reports, and Settings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final tabs = [
      const _InventoryTab(),
      _PlaceholderTab(
        title: l10n.navSales,
        icon: Icons.point_of_sale_outlined,
        emptyTitle: l10n.noSalesFound,
        emptyDesc: l10n.noSalesDesc,
      ),
      _PlaceholderTab(
        title: l10n.navReports,
        icon: Icons.bar_chart_rounded,
        emptyTitle: l10n.noDataTitle,
        emptyDesc: l10n.noDataDesc,
      ),
      const _SettingsTab(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            label: l10n.inventoryTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale_rounded),
            label: l10n.salesTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l10n.reportsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final partsAsync = ref.watch(partsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryTab),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/parts/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.add),
      ),
      body: partsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (parts) {
          if (parts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.noPartsFound,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noPartsDesc,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/parts/add'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.add),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: parts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final part = parts[index];
              final hasPhoto = part.photoLocalPath != null &&
                  File(part.photoLocalPath!).existsSync();

              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: colorScheme.surfaceContainerHighest,
                      child: hasPhoto
                          ? Image.file(
                              File(part.photoLocalPath!),
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.build_circle_outlined,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                  title: Text(
                    part.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    part.partNumber != null && part.partNumber!.isNotEmpty
                        ? 'Part: ${part.partNumber}'
                        : '${part.cachedQuantity.toStringAsFixed(0)} ${part.unit ?? ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (part.sellingPrice != null)
                        Text(
                          '${part.sellingPrice!.toStringAsFixed(0)} ብር',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: part.cachedQuantity > 0
                              ? Colors.green.withValues(alpha: 0.15)
                              : colorScheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          part.cachedQuantity > 0 ? l10n.inStock : l10n.outOfStock,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: part.cachedQuantity > 0
                                ? Colors.green.shade800
                                : colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/parts/${part.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyDesc;

  const _PlaceholderTab({
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyDesc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Business Profile Card
          if (user != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.store_rounded,
                          size: 32, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.businessName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Language Setting Tile
          const Card(
            child: LanguageSettingTile(),
          ),
          const SizedBox(height: 12),

          // Inventory & Master Data Configurations
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.directions_car_rounded, color: colorScheme.primary),
                  title: Text(l10n.brandsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.manageBrandsDesc),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/brands'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.folder_open_rounded, color: colorScheme.secondary),
                  title: Text(l10n.categoriesTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.manageCategoriesDesc),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.shelves, color: colorScheme.tertiary),
                  title: Text(l10n.locationsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.manageLocationsDesc),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/locations'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Offline Status Card
          Card(
            child: ListTile(
              leading: Icon(Icons.cloud_done_rounded, color: colorScheme.secondary),
              title: Text(
                l10n.offlineBadge,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l10n.offlineStatusNotice),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error, width: 1.5),
              minimumSize: const Size(double.infinity, AppConstants.standardButtonHeight),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              l10n.logout,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}
