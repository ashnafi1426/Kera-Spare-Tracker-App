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
                  'Configure API Base URL to connect over Wi-Fi, hotspot, or USB tether:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverController,
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'http://192.168.137.90:7000/api/v1',
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
                      label: const Text('Wi-Fi (.90)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://192.168.137.90:7000/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Wi-Fi (.6)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://192.168.137.6:7000/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('USB (127.0.0.1)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://127.0.0.1:7000/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Wi-Fi (.146)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://192.168.137.146:7000/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Emulator (10.0.2.2)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text =
                              'http://10.0.2.2:7000/api/v1';
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
                            statusMessage = null;
                            testSuccess = null;
                          });
                          try {
                            final url = serverController.text.trim();
                            final testDio = Dio(
                              BaseOptions(
                                baseUrl: url,
                                connectTimeout: const Duration(seconds: 3),
                                receiveTimeout: const Duration(seconds: 3),
                              ),
                            );
                            final res = await testDio.get('/health');
                            if (res.statusCode == 200) {
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = true;
                                statusMessage = 'Connected! Backend is reachable.';
                              });
                            } else {
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = false;
                                statusMessage = 'Server response: ${res.statusCode}';
                              });
                            }
                          } catch (err) {
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = false;
                              statusMessage = 'Connection failed. Check IP & port.';
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
                        color: testSuccess == true ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: testSuccess == true ? Colors.green : Colors.red,
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

