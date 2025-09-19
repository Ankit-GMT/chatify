import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    Future.delayed(Duration(seconds: 3),(){
      Get.off(()=> LoginScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Chatify"),
      //   centerTitle: true,
      //   backgroundColor: Get.theme.primaryColor,
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: Get.height *0.02,
          children: [
            Image.asset("assets/images/app_logo.png",scale: 4,),
            Text("Chatify",style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 32
            ),),
          ],
        ),
      ),
    );
  }
}
