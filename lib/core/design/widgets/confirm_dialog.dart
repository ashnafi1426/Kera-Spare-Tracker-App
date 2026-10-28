import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';
import '../tokens/admin_typography.dart';

/// Modal dialog requiring user confirmation before destructive or critical actions.
/// Optionally enforces entering a reason (e.g. for user suspension).
class ConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;
  final bool requireReason;
  final String? reasonLabel;
  final String? reasonHint;
  final Future<void> Function(String reason)? onConfirmedWithReason;
  final Future<void> Function()? onConfirmed;

  const ConfirmDialog({
    super.key,
    required this.title,
    String? message,
    String? description,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
    this.requireReason = false,
    this.reasonLabel,
    this.reasonHint,
    this.onConfirmedWithReason,
    this.onConfirmed,
  }) : message = message ?? description ?? '';

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? description,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    bool requireReason = false,
    String? reasonLabel,
    String? reasonHint,
    Future<void> Function(String reason)? onConfirmedWithReason,
    Future<void> Function()? onConfirmed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message ?? description ?? '',
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        requireReason: requireReason,
        reasonLabel: reasonLabel,
        reasonHint: reasonHint,
        onConfirmedWithReason: onConfirmedWithReason,
        onConfirmed: onConfirmed,
      ),
    );
  }

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final confirmColor = widget.isDestructive ? AdminColors.danger : AdminColors.primary;

    return AlertDialog(
      backgroundColor: AdminColors.surfaceOf(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        side: BorderSide(color: AdminColors.borderOf(isDark), width: 1.0),
      ),
      title: Text(
        widget.title,
        style: AdminTypography.sectionHeader(isDark).copyWith(
          fontSize: 18,
          color: widget.isDestructive ? AdminColors.danger : AdminColors.textPrimaryOf(isDark),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message,
                style: AdminTypography.body(isDark).copyWith(
                  color: AdminColors.textSecondaryOf(isDark),
                ),
              ),
              if (widget.requireReason) ...[
                const SizedBox(height: AdminSpacing.lg),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  autofocus: true,
                  style: AdminTypography.body(isDark),
                  decoration: InputDecoration(
                    labelText: widget.reasonLabel ?? widget.reasonHint ?? l10n.adminReason,
                    hintText: widget.reasonHint ?? l10n.adminSuspensionReasonHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminSpacing.radiusField),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.adminReasonRequired;
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            widget.cancelLabel ?? l10n.cancel,
            style: TextStyle(color: AdminColors.textSecondaryOf(isDark)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
            ),
          ),
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (widget.requireReason && !_formKey.currentState!.validate()) {
                    return;
                  }
                  setState(() => _isSubmitting = true);
                  try {
                    final reason = _reasonController.text.trim();
                    if (widget.onConfirmedWithReason != null) {
                      await widget.onConfirmedWithReason!(reason);
                    } else if (widget.onConfirmed != null) {
                      await widget.onConfirmed!();
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop(widget.requireReason ? reason : true);
                    }
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  widget.confirmLabel ?? l10n.confirm,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
