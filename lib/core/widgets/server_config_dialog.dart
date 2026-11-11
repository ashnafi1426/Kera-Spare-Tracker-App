import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/constants.dart';

/// Shows read-only Server Information dialog.
/// Backend is strictly locked to Render cloud production endpoint.
void showServerConfigDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.cloud_done_rounded, color: Color(0xFF173655)),
          SizedBox(width: 8),
          Expanded(child: Text('Server Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cloud Backend:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const SelectableText(
              AppConstants.defaultProductionBaseUrl,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF173655)),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Live Render Cloud Production',
                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
