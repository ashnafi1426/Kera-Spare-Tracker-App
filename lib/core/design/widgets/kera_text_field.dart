import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';

/// Industrial stacked-label text input field with prefix/suffix actions,
/// clear 2px focus ring, and localized error formatting.
class KeraTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool showClearButton;

  const KeraTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.showClearButton = false,
  });

  @override
  State<KeraTextField> createState() => _KeraTextFieldState();
}

class _KeraTextFieldState extends State<KeraTextField> {
  late TextEditingController _effectiveController;
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController(text: widget.initialValue);
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(KeraTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      _effectiveController = widget.controller!;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffix = widget.suffixIcon;

    if (widget.obscureText) {
      effectiveSuffix = IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: KeraColors.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _isObscured = !_isObscured),
        tooltip: _isObscured ? 'Show password' : 'Hide password',
      );
    } else if (widget.showClearButton && _effectiveController.text.isNotEmpty) {
      effectiveSuffix = IconButton(
        icon: const Icon(Icons.clear_rounded, color: KeraColors.textSecondary, size: 20),
        onPressed: () {
          _effectiveController.clear();
          widget.onChanged?.call('');
          setState(() {});
        },
        tooltip: 'Clear',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
            child: Text(
              widget.label!,
              style: KeraTypography.labelMedium(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: _effectiveController,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _isObscured,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          style: KeraTypography.bodyLarge(color: KeraColors.textPrimary),
          onChanged: (val) {
            widget.onChanged?.call(val);
            if (widget.showClearButton) setState(() {});
          },
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffix,
            filled: true,
            fillColor: widget.enabled ? KeraColors.surfacePure : KeraColors.surfaceMuted,
            contentPadding: KeraSpacing.inputPadding,
            border: const OutlineInputBorder(
              borderRadius: KeraRadii.borderInput,
              borderSide: BorderSide(color: KeraColors.outlineBorder),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: KeraRadii.borderInput,
              borderSide: BorderSide(color: KeraColors.outlineBorder),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: KeraRadii.borderInput,
              borderSide: BorderSide(color: KeraColors.actionBlue, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: KeraRadii.borderInput,
              borderSide: BorderSide(color: KeraColors.error, width: 1.5),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: KeraRadii.borderInput,
              borderSide: BorderSide(color: KeraColors.error, width: 2),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

