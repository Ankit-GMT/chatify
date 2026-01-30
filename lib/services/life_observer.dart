import 'package:chatify/services/presence_socket_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class LifeObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final socket = Get.find<SocketService>();

    if (state == AppLifecycleState.resumed) {
      socket.connect();
      socket.sendOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      socket.sendOnline(false);
    }
  }
}

