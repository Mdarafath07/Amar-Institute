import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Network check error: $e');
      return false;
    }
  }

  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map(
          (result) => result != ConnectivityResult.none,
    );
  }

  Future<List<ConnectivityResult>> get connectivityStatus async {
    return await _connectivity.checkConnectivity();
  }
}