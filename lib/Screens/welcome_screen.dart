import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/welcome_screen.jpg"),
              fit: BoxFit.cover),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Get.off(()=> LoginScreen());
              },
              child: Container(
                height: Get.height * 0.05,
                width: Get.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withAlpha(100),
                        AppColors.primary
                      ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withAlpha(70),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                ),
                child: Center(
                    child: Text(
                  "Get Started",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: Colors.white),
                ),),
              ),
            ),
            SizedBox(
              height: Get.height * 0.09,
            ),
          ],
        ),
      ),
    );
  }
}
