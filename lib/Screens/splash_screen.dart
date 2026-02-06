import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/welcome_screen.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final box = GetStorage();
    final token = box.read("accessToken");
    final myId = box.read("userId");
    if (myId != null) {
      Get.find<MessageController>().onUserLoggedIn(myId);
    }

    Future.delayed(Duration(seconds: 3),(){
      Get.off(()=> token!= null ? MainScreen() : WelcomeScreen());
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.asset("assets/images/splash_screen.png",fit: BoxFit.cover,),
    );
  }
}
