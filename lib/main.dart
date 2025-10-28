import 'package:chatify/Screens/splash_screen.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/theme.dart';
import 'package:chatify/widgets/zego_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final navigatorKey = GlobalKey<NavigatorState>();
  if (!await Permission.contacts.isGranted) {
    await Permission.contacts.request();
  }
  // await GetStorage.init();
  // final box = GetStorage();
// box.erase();
//   await initZego(box.read("userId") ?? "", box.read("userName") ?? '');
//   print("User ID: ${box.read('userId')}");
//   print("User Name: ${box.read('userName')}");
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  runApp(MyApp(
    navigatorKey: navigatorKey,
  ));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final themeController = Get.find<ThemeController>();

   MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Chatify',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeController.isDarkMode.value? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
      // builder: (context, child) {
      //   return Stack(
      //     children: [
      //       child!,
      //       ZegoUIKitPrebuiltCallMiniOverlayPage(
      //         contextQuery: () {
      //           return navigatorKey.currentState!.context;
      //         },
      //       ),
      //     ],
      //   );
      // },
    );
  }
}
