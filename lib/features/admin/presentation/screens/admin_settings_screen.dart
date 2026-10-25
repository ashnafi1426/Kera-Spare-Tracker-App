import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // App Version Controllers
  late final TextEditingController _versionController;
  bool _enforceVersion = false;

  // Announcement Controllers
  bool _announcementActive = false;
  late final TextEditingController _annTitleAmController;
  late final TextEditingController _annTitleEnController;
  late final TextEditingController _annBodyAmController;
  late final TextEditingController _annBodyEnController;

  // Maintenance Controllers
  bool _maintenanceEnabled = false;
  late final TextEditingController _maintMessageAmController;
  late final TextEditingController _maintMessageEnController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _versionController = TextEditingController();
    _annTitleAmController = TextEditingController();
    _annTitleEnController = TextEditingController();
    _annBodyAmController = TextEditingController();
    _annBodyEnController = TextEditingController();
    _maintMessageAmController = TextEditingController();
    _maintMessageEnController = TextEditingController();
  }

  @override
  void dispose() {
    _versionController.dispose();
    _annTitleAmController.dispose();
    _annTitleEnController.dispose();
    _annBodyAmController.dispose();
    _annBodyEnController.dispose();
    _maintMessageAmController.dispose();
    _maintMessageEnController.dispose();
    super.dispose();
  }

  void _syncWithState(AdminSettingsState state) {
    if (_initialized) return;
    _versionController.text = state.minAppVersion.version;
    _enforceVersion = state.minAppVersion.enforce;

    _announcementActive = state.announcement.active;
    _annTitleAmController.text = state.announcement.titleAm;
    _annTitleEnController.text = state.announcement.titleEn;
    _annBodyAmController.text = state.announcement.bodyAm;
    _annBodyEnController.text = state.announcement.bodyEn;

    _maintenanceEnabled = state.maintenance.enabled;
    _maintMessageAmController.text = state.maintenance.messageAm;
    _maintMessageEnController.text = state.maintenance.messageEn;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settingsState = ref.watch(adminSettingsProvider);

    if (!settingsState.isLoading && !_initialized) {
      _syncWithState(settingsState);
    }

    ref.listen(adminSettingsProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminAppSettingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () {
              _initialized = false;
              ref.read(adminSettingsProvider.notifier).loadSettings();
            },
          ),
        ],
      ),
      body: settingsState.isLoading
          ? const Center(child: AppLoadingIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _initialized = false;
                await ref.read(adminSettingsProvider.notifier).loadSettings();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildVersionSection(context, l10n, theme, settingsState),
                        const SizedBox(height: 20),
                        _buildAnnouncementSection(context, l10n, theme, settingsState),
                        const SizedBox(height: 20),
                        _buildMaintenanceSection(context, l10n, theme, settingsState),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildVersionSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    AdminSettingsState state,
  ) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.adminMinAppVersion,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminMinAppVersionDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _versionController,
              decoration: InputDecoration(
                labelText: l10n.adminVersionStringLabel,
                hintText: '1.0.0',
                prefixIcon: const Icon(Icons.numbers),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminEnforceMinVersion),
              subtitle: Text(l10n.adminEnforceMinVersionDesc),
              value: _enforceVersion,
              onChanged: (val) => setState(() => _enforceVersion = val),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.save),
                onPressed: state.isSaving
                    ? null
                    : () {
                        final v = _versionController.text.trim();
                        if (v.isNotEmpty) {
                          ref
                              .read(adminSettingsProvider.notifier)
                              .saveMinAppVersion(v, _enforceVersion);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    AdminSettingsState state,
  ) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.adminAnnouncementSettings,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminAnnouncementDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminAnnouncementActive),
              subtitle: Text(l10n.adminAnnouncementActiveDesc),
              value: _announcementActive,
              onChanged: (val) => setState(() => _announcementActive = val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _annTitleAmController,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementTitleAm,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _annBodyAmController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementBodyAm,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _annTitleEnController,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementTitleEn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _annBodyEnController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementBodyEn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.save),
                onPressed: state.isSaving
                    ? null
                    : () {
                        final ann = AdminAnnouncement(
                          active: _announcementActive,
                          titleAm: _annTitleAmController.text.trim(),
                          titleEn: _annTitleEnController.text.trim(),
                          bodyAm: _annBodyAmController.text.trim(),
                          bodyEn: _annBodyEnController.text.trim(),
                        );
                        ref.read(adminSettingsProvider.notifier).saveAnnouncement(ann);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    AdminSettingsState state,
  ) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle, color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Text(
                  l10n.adminMaintenanceMode,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminMaintenanceDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminMaintenanceActive),
              subtitle: Text(l10n.adminMaintenanceActiveDesc),
              value: _maintenanceEnabled,
              onChanged: (val) => setState(() => _maintenanceEnabled = val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maintMessageAmController,
              decoration: InputDecoration(
                labelText: l10n.adminMaintenanceMessageAm,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maintMessageEnController,
              decoration: InputDecoration(
                labelText: l10n.adminMaintenanceMessageEn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maintenanceEnabled ? theme.colorScheme.error : null,
                  foregroundColor: _maintenanceEnabled ? Colors.white : null,
                ),
                icon: const Icon(Icons.save),
                label: Text(l10n.save),
                onPressed: state.isSaving
                    ? null
                    : () {
                        final maint = AdminMaintenanceMode(
                          enabled: _maintenanceEnabled,
                          messageAm: _maintMessageAmController.text.trim(),
                          messageEn: _maintMessageEnController.text.trim(),
                        );
                        ref.read(adminSettingsProvider.notifier).saveMaintenance(maint);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
