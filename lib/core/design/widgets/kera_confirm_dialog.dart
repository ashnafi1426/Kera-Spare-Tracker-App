import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';
import 'kera_button.dart';
import 'kera_text_field.dart';

/// Modal dialog requiring user confirmation before destructive or critical actions.
/// Designed for high-contrast visibility and grease-friendly touch targets.
class KeraConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final bool requireReason;
  final String? reasonLabel;
  final String? reasonHint;
  final Future<void> Function(String reason)? onConfirmedWithReason;
  final Future<void> Function()? onConfirmed;

  const KeraConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'አረጋግጥ (Confirm)',
    this.cancelLabel = 'ይቅር (Cancel)',
    this.isDestructive = false,
    this.requireReason = false,
    this.reasonLabel,
    this.reasonHint,
    this.onConfirmedWithReason,
    this.onConfirmed,
  });

  /// Displays the confirmation dialog and returns true if confirmed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'አረጋግጥ (Confirm)',
    String cancelLabel = 'ይቅር (Cancel)',
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
      builder: (ctx) => KeraConfirmDialog(
        title: title,
        message: message,
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
  State<KeraConfirmDialog> createState() => _KeraConfirmDialogState();
}

class _KeraConfirmDialogState extends State<KeraConfirmDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (widget.requireReason) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.onConfirmedWithReason != null) {
        await widget.onConfirmedWithReason!(_reasonController.text.trim());
      } else if (widget.onConfirmed != null) {
        await widget.onConfirmed!();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KeraColors.surfacePure,
      shape: const RoundedRectangleBorder(borderRadius: KeraRadii.borderCard),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.isDestructive ? KeraColors.errorBg : KeraColors.actionBlueTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isDestructive ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      color: widget.isDestructive ? KeraColors.error : KeraColors.actionBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: KeraSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: KeraTypography.titleMedium(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KeraSpacing.md),

              // Message Body
              Text(
                widget.message,
                style: KeraTypography.bodyLarge(color: KeraColors.textSecondary),
              ),

              // Optional Reason Field
              if (widget.requireReason) ...[
                const SizedBox(height: KeraSpacing.lg),
                KeraTextField(
                  controller: _reasonController,
                  label: widget.reasonLabel ?? 'ምክንያት / Reason',
                  hintText: widget.reasonHint ?? 'የእርምጃውን ምክንያት ያስገቡ...',
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'ምክንያት ማስገባት ግዴታ ነው (Reason required)';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: KeraSpacing.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: KeraButton.outlined(
                      label: widget.cancelLabel,
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: KeraSpacing.md),
                  Expanded(
                    child: KeraButton.primary(
                      label: widget.confirmLabel,
                      isLoading: _isSubmitting,
                      onPressed: _handleConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

