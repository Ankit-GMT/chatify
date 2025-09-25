import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/bottom_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    // Get.put(UserController(), permanent: true);
    // Get.put(ProfileController(), permanent: true);
    Get.put(BottomController(), permanent: true);
    Get.put(TabBarController(), permanent: true);
  }
}