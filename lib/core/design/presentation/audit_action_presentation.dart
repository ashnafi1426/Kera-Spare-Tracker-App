import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../tokens/admin_colors.dart';

class AuditActionPresentation {
  final String label;
  final IconData icon;
  final Color color;
  final Color tintColor;

  const AuditActionPresentation({
    required this.label,
    required this.icon,
    required this.color,
    required this.tintColor,
  });

  /// Formats IPv4-mapped IPv6 addresses (e.g. ::ffff:192.168.1.1) to clean IPv4.
  static String cleanIp(String? ip) {
    if (ip == null || ip.isEmpty) return '-';
    if (ip.startsWith('::ffff:')) {
      return ip.substring(7);
    }
    return ip;
  }

  /// Maps an audit log action code to an accessible visual presentation.
  static AuditActionPresentation resolve(String action, AppLocalizations l10n) {
    switch (action.toUpperCase()) {
      case 'USER_SUSPENDED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionUserSuspended,
          icon: Icons.block_rounded,
          color: AdminColors.danger,
          tintColor: AdminColors.dangerTint,
        );
      case 'USER_REACTIVATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionUserReactivated,
          icon: Icons.check_circle_outline_rounded,
          color: AdminColors.success,
          tintColor: AdminColors.successTint,
        );
      case 'USER_PASSWORD_RESET':
        return AuditActionPresentation(
          label: l10n.adminAuditActionPasswordReset,
          icon: Icons.lock_reset_rounded,
          color: AdminColors.warning,
          tintColor: AdminColors.warningTint,
        );
      case 'USER_DELETED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionUserDeleted,
          icon: Icons.person_remove_rounded,
          color: AdminColors.danger,
          tintColor: AdminColors.dangerTint,
        );
      case 'BRAND_CREATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionBrandCreated,
          icon: Icons.add_circle_outline_rounded,
          color: AdminColors.success,
          tintColor: AdminColors.successTint,
        );
      case 'BRAND_UPDATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionBrandUpdated,
          icon: Icons.edit_note_rounded,
          color: AdminColors.info,
          tintColor: AdminColors.infoTint,
        );
      case 'CATEGORY_CREATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionCategoryCreated,
          icon: Icons.create_new_folder_outlined,
          color: AdminColors.success,
          tintColor: AdminColors.successTint,
        );
      case 'CATEGORY_UPDATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionCategoryUpdated,
          icon: Icons.folder_open_rounded,
          color: AdminColors.info,
          tintColor: AdminColors.infoTint,
        );
      case 'UNIT_CREATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionUnitCreated,
          icon: Icons.square_foot_rounded,
          color: AdminColors.success,
          tintColor: AdminColors.successTint,
        );
      case 'UNIT_UPDATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionUnitUpdated,
          icon: Icons.straighten_rounded,
          color: AdminColors.info,
          tintColor: AdminColors.infoTint,
        );
      case 'APP_SETTINGS_UPDATED':
      case 'SETTINGS_UPDATED':
        return AuditActionPresentation(
          label: l10n.adminAuditActionSettingsUpdated,
          icon: Icons.tune_rounded,
          color: AdminColors.warning,
          tintColor: AdminColors.warningTint,
        );
      default:
        // Fallback: format CODE_WORDS as "Code Words"
        final readable = action
            .toLowerCase()
            .split('_')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
        return AuditActionPresentation(
          label: readable.isNotEmpty ? readable : action,
          icon: Icons.info_outline_rounded,
          color: AdminColors.info,
          tintColor: AdminColors.infoTint,
        );
    }
  }
}
