import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/welcome_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

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

    // if(token!=null){
    //   profileController.fetchUserProfile();
    // }
    Future.delayed(Duration(seconds: 3),(){
      Get.off(()=> token!= null ? MainScreen() : WelcomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: Get.height *0.02,
          children: [
            Image.asset("assets/images/app_logo.png",scale: 4,),
            Text("Chatify",style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 32,
            ),),
          ],
        ),
      ),
    );
  }
}
