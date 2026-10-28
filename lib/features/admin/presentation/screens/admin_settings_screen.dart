import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/confirm_dialog.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../security/presentation/widgets/app_lock_settings_card.dart';
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

  bool _hasUnsavedChanges(AdminSettingsState state) {
    if (!_initialized) return false;
    final verChanged = _versionController.text.trim() != state.minAppVersion.version ||
        _enforceVersion != state.minAppVersion.enforce;
    final annChanged = _announcementActive != state.announcement.active ||
        _annTitleAmController.text.trim() != state.announcement.titleAm ||
        _annTitleEnController.text.trim() != state.announcement.titleEn ||
        _annBodyAmController.text.trim() != state.announcement.bodyAm ||
        _annBodyEnController.text.trim() != state.announcement.bodyEn;
    final maintChanged = _maintenanceEnabled != state.maintenance.enabled ||
        _maintMessageAmController.text.trim() != state.maintenance.messageAm ||
        _maintMessageEnController.text.trim() != state.maintenance.messageEn;
    return verChanged || annChanged || maintChanged;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(adminSettingsProvider);

    if (!settingsState.isLoading && !_initialized) {
      _syncWithState(settingsState);
    }

    ref.listen(adminSettingsProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage ?? l10n.adminSaveSuccess),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    });

    return PopScope(
      canPop: !_hasUnsavedChanges(settingsState),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => ConfirmDialog(
            title: l10n.adminUnsavedChangesTitle,
            description: l10n.adminUnsavedChangesMessage,
            confirmLabel: l10n.adminDiscard,
            isDestructive: true,
            requireReason: false,
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AdminColors.background,
        appBar: AppBar(
          title: Text(l10n.adminAppSettingsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.refresh,
              onPressed: () {
                _initialized = false;
                ref.read(adminSettingsProvider.notifier).loadSettings();
              },
            ),
          ],
        ),
        body: settingsState.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AdminSpacing.lg),
                child: SkeletonListLoader(count: 4),
              )
            : RefreshIndicator(
                color: AdminColors.primary,
                onRefresh: () async {
                  _initialized = false;
                  await ref.read(adminSettingsProvider.notifier).loadSettings();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.lg,
                    vertical: AdminSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildVersionSection(context, l10n, settingsState),
                          const SizedBox(height: AdminSpacing.xl),
                          _buildAnnouncementSection(context, l10n, settingsState),
                          const SizedBox(height: AdminSpacing.xl),
                          _buildMaintenanceSection(context, l10n, settingsState),
                          const SizedBox(height: AdminSpacing.xl),
                          const AppLockSettingsCard(),
                          const SizedBox(height: AdminSpacing.xxl),
                        ],
                      ),
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
    AdminSettingsState state,
  ) {
    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AdminSpacing.sm),
                decoration: const BoxDecoration(
                  color: AdminColors.infoTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AdminColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminMinAppVersion,
                      style: AdminTypography.h3,
                    ),
                    Text(
                      l10n.adminMinAppVersionDesc,
                      style: AdminTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          const Divider(height: 1, color: AdminColors.border),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            controller: _versionController,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminVersionStringLabel,
              hintText: '1.0.0',
              helperText: l10n.adminVersionHelper,
              helperStyle: AdminTypography.caption,
              prefixIcon: const Icon(Icons.tag_rounded, color: AdminColors.textSecondary),
            ),
          ),
          const SizedBox(height: AdminSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AdminColors.primary,
            activeThumbColor: Colors.white,
            title: Text(
              l10n.adminEnforceMinVersion,
              style: AdminTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.adminEnforceMinVersionDesc,
              style: AdminTypography.caption,
            ),
            value: _enforceVersion,
            onChanged: (val) => setState(() => _enforceVersion = val),
          ),
          const SizedBox(height: AdminSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
                ),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
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
    );
  }

  Widget _buildAnnouncementSection(
    BuildContext context,
    AppLocalizations l10n,
    AdminSettingsState state,
  ) {
    final previewTitle = Localizations.localeOf(context).languageCode == 'am'
        ? (_annTitleAmController.text.isNotEmpty ? _annTitleAmController.text : _annTitleEnController.text)
        : (_annTitleEnController.text.isNotEmpty ? _annTitleEnController.text : _annTitleAmController.text);
    final previewBody = Localizations.localeOf(context).languageCode == 'am'
        ? (_annBodyAmController.text.isNotEmpty ? _annBodyAmController.text : _annBodyEnController.text)
        : (_annBodyEnController.text.isNotEmpty ? _annBodyEnController.text : _annBodyAmController.text);

    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AdminSpacing.sm),
                decoration: const BoxDecoration(
                  color: AdminColors.infoTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AdminColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminAnnouncementSettings,
                      style: AdminTypography.h3,
                    ),
                    Text(
                      l10n.adminAnnouncementDesc,
                      style: AdminTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          const Divider(height: 1, color: AdminColors.border),
          const SizedBox(height: AdminSpacing.md),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AdminColors.primary,
            activeThumbColor: Colors.white,
            title: Text(
              l10n.adminAnnouncementActive,
              style: AdminTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.adminAnnouncementActiveDesc,
              style: AdminTypography.caption,
            ),
            value: _announcementActive,
            onChanged: (val) => setState(() => _announcementActive = val),
          ),
          const SizedBox(height: AdminSpacing.md),

          // Live Preview Banner
          if (_announcementActive) ...[
            Container(
              padding: const EdgeInsets.all(AdminSpacing.md),
              decoration: BoxDecoration(
                color: AdminColors.infoTint,
                borderRadius: BorderRadius.circular(AdminSpacing.radiusField),
                border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.preview_rounded, size: 16, color: AdminColors.primary),
                      const SizedBox(width: AdminSpacing.xs),
                      Text(
                        l10n.adminLivePreview,
                        style: AdminTypography.caption.copyWith(
                          color: AdminColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.xs),
                  Text(
                    previewTitle.isNotEmpty ? previewTitle : 'Announcement Title',
                    style: AdminTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (previewBody.isNotEmpty) ...[
                    const SizedBox(height: AdminSpacing.xs),
                    Text(previewBody, style: AdminTypography.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AdminSpacing.md),
          ],

          TextFormField(
            controller: _annTitleAmController,
            onChanged: (_) => setState(() {}),
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminAnnouncementTitleAm,
            ),
          ),
          const SizedBox(height: AdminSpacing.sm),
          TextFormField(
            controller: _annBodyAmController,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminAnnouncementBodyAm,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            controller: _annTitleEnController,
            onChanged: (_) => setState(() {}),
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminAnnouncementTitleEn,
            ),
          ),
          const SizedBox(height: AdminSpacing.sm),
          TextFormField(
            controller: _annBodyEnController,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminAnnouncementBodyEn,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
                ),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
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
    );
  }

  Widget _buildMaintenanceSection(
    BuildContext context,
    AppLocalizations l10n,
    AdminSettingsState state,
  ) {
    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AdminSpacing.sm),
                decoration: const BoxDecoration(
                  color: AdminColors.dangerTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: AdminColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminMaintenanceMode,
                      style: AdminTypography.h3.copyWith(
                        color: _maintenanceEnabled ? AdminColors.danger : null,
                      ),
                    ),
                    Text(
                      l10n.adminMaintenanceDesc,
                      style: AdminTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          const Divider(height: 1, color: AdminColors.border),
          const SizedBox(height: AdminSpacing.md),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AdminColors.danger,
            activeThumbColor: Colors.white,
            title: Text(
              l10n.adminMaintenanceActive,
              style: AdminTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: _maintenanceEnabled ? AdminColors.danger : null,
              ),
            ),
            subtitle: Text(
              l10n.adminMaintenanceActiveDesc,
              style: AdminTypography.caption,
            ),
            value: _maintenanceEnabled,
            onChanged: (val) => setState(() => _maintenanceEnabled = val),
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            controller: _maintMessageAmController,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminMaintenanceMessageAm,
            ),
          ),
          const SizedBox(height: AdminSpacing.sm),
          TextFormField(
            controller: _maintMessageEnController,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.adminMaintenanceMessageEn,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _maintenanceEnabled ? AdminColors.danger : AdminColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
                ),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
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
    );
  }
}
