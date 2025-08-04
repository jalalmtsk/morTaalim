// connectivity_service.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  List<ConnectivityResult> get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus.any((s) => s != ConnectivityResult.none);

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _subscription = _connectivity.onConnectivityChanged
          .distinct() // Only emit when status actually changes
          .listen((result) {
        _connectionStatus = result;
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) print("Connectivity error: $e");
    }
  }


  bool _isActive = true;

  void pauseMonitoring() {
    _subscription?.pause();
    _isActive = false;
  }

  void resumeMonitoring() {
    if (!_isActive) {
      _subscription?.resume();
      _isActive = true;
    }
  }



  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}