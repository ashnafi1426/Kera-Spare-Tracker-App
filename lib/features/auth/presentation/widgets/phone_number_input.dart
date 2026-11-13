import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import 'auth_colors.dart';

/// Reusable Ethiopian Phone Number input matching Figma specifications:
/// - Bilingual Label: "Phone number ስልክ ቁጥር" with optional gold asterisk [*]
/// - [+251 ▾] country code dropdown button
/// - Mask/hint "9XX XXX XXX" with input formatting & validation
class PhoneNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const PhoneNumberInput({
    super.key,
    required this.controller,
    this.isRequired = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = AuthColors.textPrimaryOf(isDark);
    final textSecondary = AuthColors.textSecondaryOf(isDark);
    final borderColor = AuthColors.borderOf(isDark);
    final inputBg = AuthColors.inputBgOf(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bilingual Label Row
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Phone number',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ስልክ ቁጥር',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 7),

        // Input Field Container
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+]')),
            LengthLimitingTextInputFormatter(13),
          ],
          onChanged: onChanged,
          validator: validator ?? Validators.validateEthiopianPhone,
          decoration: InputDecoration(
            hintText: '9XX XXX XXX',
            hintStyle: TextStyle(
              color: textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: borderColor, width: 1.0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+251',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuthColors.primaryNavy, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuthColors.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuthColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
