import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';

/// Sticky date separator for lists.
class DateGroupHeader extends StatelessWidget {
  final String dateText;
  final String? rightText;

  const DateGroupHeader({
    super.key,
    required this.dateText,
    this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.scaffoldBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
          if (rightText != null)
            Text(
              rightText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

