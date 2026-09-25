import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final instance = ConnectivityService._();
  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async => !(await _connectivity.checkConnectivity())
      .contains(ConnectivityResult.none);
}
