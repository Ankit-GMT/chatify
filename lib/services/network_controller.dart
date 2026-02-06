import 'dart:async';
import 'package:chatify/services/presence_socket_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _sub = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    print("🌐 Connectivity results: $results");
    isOnline.value = !results.contains(ConnectivityResult.none);
  }

  void retry() {
    _init();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
