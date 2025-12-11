import 'package:get/get.dart';

class FloatingCallBubbleService extends GetxService {
  static FloatingCallBubbleService get to => Get.find();

  final isVisible = false.obs;

  void hide() {
    isVisible.value = false;
  }

}
