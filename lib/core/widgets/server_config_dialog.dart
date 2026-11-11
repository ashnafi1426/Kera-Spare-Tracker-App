import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/data/repositories/api_admin_repository.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/auth/data/repositories/api_auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../constants/constants.dart';
import '../services/session_store.dart';

/// Opens the Server Connection Settings dialog.
void showServerConfigDialog(BuildContext context, WidgetRef ref) {
  final current = AppConstants.apiBaseUrl;
  final serverController = TextEditingController(text: current);
  bool isTesting = false;
  String? statusMessage;
  bool? testSuccess;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final colorScheme = Theme.of(ctx).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings_ethernet_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Server Settings')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure API Base URL for Render Cloud, Wi-Fi, or USB tether:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverController,
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://kera-spare-tracker-api.onrender.com/api/v1',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setDialogState(() => serverController.clear()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quick Presets:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_done_rounded, size: 16),
                      label: const Text('Render Cloud (Default)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'https://kera-spare-tracker-api.onrender.com/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi_rounded, size: 16),
                      label: const Text('Local Wi-Fi (192.168.137.184)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://192.168.137.184:7000/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.usb_rounded, size: 16),
                      label: const Text('Local USB (127.0.0.1)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://127.0.0.1:7000/api/v1';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() {
                            isTesting = true;
                            statusMessage = 'Connecting... (Render cloud server may take 30-45s if waking up)';
                            testSuccess = null;
                          });
                          try {
                            final rawUrl = serverController.text.trim();
                            final isCloud = rawUrl.contains('onrender.com');
                            final timeout = Duration(seconds: isCloud ? 45 : 5);
                            final testDio = Dio(
                              BaseOptions(
                                connectTimeout: timeout,
                                receiveTimeout: timeout,
                              ),
                            );
                            // Probe /api/v1/health or /health depending on format
                            final target = rawUrl.endsWith('/api/v1')
                                ? '$rawUrl/health'
                                : (rawUrl.endsWith('/') ? '${rawUrl}health' : '$rawUrl/health');
                            final res = await testDio.get(target);
                            if (res.statusCode == 200) {
                              final db = (res.data is Map && res.data['database'] != null)
                                  ? ' (Database: ${res.data['database']})'
                                  : '';
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = true;
                                statusMessage = 'Connected! Backend is healthy$db.';
                              });
                            } else {
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = false;
                                statusMessage = 'Server response: ${res.statusCode}';
                              });
                            }
                          } catch (err) {
                            final errMsg = (err is DioException && err.type == DioExceptionType.connectionTimeout)
                                ? 'Connection timeout. If server was sleeping, please retry in 10s.'
                                : 'Connection failed. Check network & address.';
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = false;
                              statusMessage = errMsg;
                            });
                          }
                        },
                  icon: isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Test Connection'),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        testSuccess == true
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 16,
                        color: testSuccess == true ? colorScheme.primary : const Color(0xFFB35F00),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: testSuccess == true ? colorScheme.primary : const Color(0xFFB35F00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final target = serverController.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                if (target.isNotEmpty) {
                  AppConstants.setApiBaseUrl(target);
                  final sessionStore = ref.read(sessionStoreProvider);
                  await sessionStore.saveApiBaseUrl(target);

                  final authRepo = ref.read(authRepositoryProvider);
                  if (authRepo is ApiAuthRepository) {
                    authRepo.dio.options.baseUrl = target;
                  }

                  final adminRepo = ref.read(adminRepositoryProvider);
                  if (adminRepo is ApiAdminRepository) {
                    adminRepo.dio.options.baseUrl = '$target/admin';
                  }

                  // Refresh any active admin views
                  ref.invalidate(adminDashboardProvider);
                  try {
                    unawaited(ref.read(adminOwnersProvider.notifier).loadOwners());
                  } catch (_) {}
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: $target'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save & Apply'),
            ),
          ],
        );
      },
    ),
  );
}

