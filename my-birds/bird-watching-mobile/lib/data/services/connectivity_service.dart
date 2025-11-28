import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity;
  StreamController<bool>? _connectivityStreamController;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of connectivity changes (true = connected, false = disconnected)
  Stream<bool> get connectivityStream {
    _connectivityStreamController ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _connectivityStreamController!.stream;
  }

  StreamSubscription<ConnectivityResult>? _subscription;

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        final isConnected = await _checkConnectivityFromResult(result);
        _connectivityStreamController?.add(isConnected);
        print('[ConnectivityService] Connectivity changed: $isConnected');
      },
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Check if device is connected to a network
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return await _checkConnectivityFromResult(result);
    } catch (e) {
      print('[ConnectivityService Error] Failed to check connectivity: $e');
      return false;
    }
  }

  /// Check connectivity from result
  Future<bool> _checkConnectivityFromResult(ConnectivityResult result) async {
    // If no connectivity or only bluetooth, consider disconnected
    if (result == ConnectivityResult.none || 
        result == ConnectivityResult.bluetooth) {
      return false;
    }

    // Check for actual internet access
    return await hasInternetAccess();
  }

  /// Check if device has actual internet access (not just network connection)
  Future<bool> hasInternetAccess() async {
    try {
      // Try to lookup a reliable host
      final result = await InternetAddress.lookup('google.com');
      final hasAccess = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      print('[ConnectivityService] Internet access: $hasAccess');
      return hasAccess;
    } on SocketException catch (_) {
      print('[ConnectivityService] No internet access (SocketException)');
      return false;
    } catch (e) {
      print('[ConnectivityService Error] Failed to check internet access: $e');
      return false;
    }
  }

  /// Get current connectivity type
  Future<ConnectivityResult> getConnectivityType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
    } catch (e) {
      print('[ConnectivityService Error] Failed to get connectivity type: $e');
      return ConnectivityResult.none;
    }
  }

  /// Check if connected via WiFi
  Future<bool> isWifiConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.wifi;
    } catch (e) {
      print('[ConnectivityService Error] Failed to check WiFi: $e');
      return false;
    }
  }

  /// Check if connected via mobile data
  Future<bool> isMobileConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile;
    } catch (e) {
      print('[ConnectivityService Error] Failed to check mobile: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityStreamController?.close();
    _connectivityStreamController = null;
    print('[ConnectivityService] Disposed');
  }
}
