import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_config_service.dart';
import '../services/storage_service.dart';

final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  return AppConfigService();
});

class AppConfigState {
  final AppConfig config;
  final bool isLoading;
  final String? dismissedAnnouncementHash;

  const AppConfigState({
    required this.config,
    this.isLoading = false,
    this.dismissedAnnouncementHash,
  });

  bool get shouldShowAnnouncement {
    final ann = config.announcement;
    if (!ann.active) return false;
    if (ann.titleAm.isEmpty &&
        ann.titleEn.isEmpty &&
        ann.bodyAm.isEmpty &&
        ann.bodyEn.isEmpty) {
      return false;
    }
    return dismissedAnnouncementHash != ann.uniqueHash;
  }

  AppConfigState copyWith({
    AppConfig? config,
    bool? isLoading,
    String? dismissedAnnouncementHash,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      dismissedAnnouncementHash:
          dismissedAnnouncementHash ?? this.dismissedAnnouncementHash,
    );
  }
}

class AppConfigNotifier extends AsyncNotifier<AppConfigState> {
  static const _dismissedKey = 'kera_dismissed_announcement_hash';
  final _storage = defaultSecureStorage;
  StreamSubscription? _connSub;

  @override
  Future<AppConfigState> build() async {
    final service = ref.read(appConfigServiceProvider);

    // Non-blocking background fetch so initial frame renders instantly without waiting for disk or network
    unawaited(
      Future.microtask(() async {
        try {
          final dismissedHash = await _storage.read(key: _dismissedKey);
          final config = await service.fetchAppConfig();
          final current = state.value;
          if (current != null) {
            state = AsyncValue.data(
              current.copyWith(
                config: config,
                dismissedAnnouncementHash: dismissedHash,
              ),
            );
          }
        } catch (_) {}
      }),
    );

    _connSub = service.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        refreshConfig();
      }
    });

    ref.onDispose(() {
      _connSub?.cancel();
    });

    return AppConfigState(
      config: AppConfig.defaults(),
    );
  }

  Future<void> refreshConfig() async {
    final service = ref.read(appConfigServiceProvider);
    final fresh = await service.fetchAppConfig();
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(config: fresh));
    }
  }

  Future<void> dismissAnnouncement() async {
    final current = state.value;
    if (current == null) return;
    final hash = current.config.announcement.uniqueHash;
    await _storage.write(key: _dismissedKey, value: hash);
    state = AsyncValue.data(
      current.copyWith(dismissedAnnouncementHash: hash),
    );
  }
}

final appConfigNotifierProvider =
    AsyncNotifierProvider<AppConfigNotifier, AppConfigState>(
  AppConfigNotifier.new,
);
