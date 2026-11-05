import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// NetworkMonitor provides real-time network connectivity updates and online status.
class NetworkMonitor {
  final Connectivity _connectivity;

  NetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Checks current online status.
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasActiveConnection(results);
    } catch (_) {
      return false;
    }
  }

  /// Reactive stream of connectivity changes.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasActiveConnection);
  }

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }
}

/// Riverpod provider for NetworkMonitor.
final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  return NetworkMonitor();
});

/// Riverpod stream provider for live online status.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final monitor = ref.watch(networkMonitorProvider);
  yield await monitor.isOnline();
  yield* monitor.onConnectivityChanged;
});
