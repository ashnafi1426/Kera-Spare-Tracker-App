import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/kera_colors.dart';

/// Tactile quantity stepper with 44-48px touch targets.
class QuantityStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double? max;
  final double step;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = max == null || value < max!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          onTap: () {
            if (canDecrement) {
              HapticFeedback.selectionClick();
              onChanged((value - step).clamp(min, max ?? double.infinity));
            }
          },
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add_rounded,
          enabled: canIncrement,
          onTap: () {
            if (canIncrement) {
              HapticFeedback.selectionClick();
              onChanged(value + step);
            }
          },
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: KeraColors.border),
        ),
        onPressed: enabled ? onTap : null,
        child: Icon(icon, size: 20, color: enabled ? KeraColors.navy800 : KeraColors.disabledColor),
      ),
    );
  }
}

