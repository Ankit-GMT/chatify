import 'package:chatify/home_screen.dart';
import 'package:chatify/login_screen.dart';
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
            Image.asset("assets/images/app_logo.png"),
            Text("Chatify",style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Color(0xffC35E31),
              fontSize: 32
            ),),
          ],
        ),
      ),
    );
  }
}
