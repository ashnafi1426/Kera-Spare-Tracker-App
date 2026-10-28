import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/database_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/services/initial_sync_service.dart';

/// Screen displayed on first login on a new phone while pulling catalog from server (Rule 6).
/// As soon as the first page (50 items) is saved to Drift, automatically navigates to /home.
class InitialSyncScreen extends ConsumerStatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  ConsumerState<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends ConsumerState<InitialSyncScreen> {
  int _downloaded = 0;
  int _total = 0;
  bool _firstBatchReady = false;
  StreamSubscription<InitialSyncProgress>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  void _startSync() {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      context.go('/login');
      return;
    }

    final repo = ref.read(apiAuthRepositoryProvider);
    final db = ref.read(appDatabaseProvider);
    final service = InitialSyncService(dio: repo.dio, db: db);

    _sub = service.pullInitialCatalog(user.ownerId).listen((progress) {
      if (!mounted) return;
      setState(() {
        _downloaded = progress.downloaded;
        _total = progress.total;
        _firstBatchReady = progress.firstBatchReady;
      });

      // Rule 6: Navigate to inventory screen as soon as the first page is written to Drift
      if (progress.firstBatchReady && mounted) {
        // Small delay so user sees initial confirmation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/home');
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    final progressVal = (_total > 0) ? (_downloaded / _total).clamp(0.0, 1.0) : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.initialSyncTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.initialSyncSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Text(
                  _total > 0
                      ? '$_downloaded / $_total parts'
                      : 'Connecting to server...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_firstBatchReady) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Proceed to Inventory'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
