import 'package:chatify/Screens/edit_profile_screen.dart';
import 'package:chatify/Screens/home_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/bottom_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final bottomController = Get.find<BottomController>();

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: bottomController.currentIndex.value,
        children: [
          HomeScreen(),
          Center(child: Text("Calls")),
          Center(child: Text("Video Calls")),
          EditProfileScreen(),
        ],
      ),),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 60,
        width: Get.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                bottomController.currentIndex.value=0;
              },
              icon: Image.asset("assets/images/bottom_chat.png",scale: 2,),
            ),
            VerticalDivider(
              color: AppColors.botttomGrey.withAlpha(90),
              thickness: 1,
              indent: 22,
              endIndent: 22,
            ),
            IconButton(
              onPressed: () {
                bottomController.currentIndex.value=1;
              },
              icon: Image.asset("assets/images/bottom_call.png",scale: 2,),
            ),
            VerticalDivider(
              color: AppColors.botttomGrey.withAlpha(90),
              thickness: 1,
              indent: 22,
              endIndent: 22,
            ),
            IconButton(
              onPressed: () {
                bottomController.currentIndex.value=2;
              },
              icon: Image.asset("assets/images/bottom_videocall.png",scale: 2,),
            ),
            VerticalDivider(
              color: AppColors.botttomGrey.withAlpha(90),
              thickness: 1,
              indent: 22,
              endIndent: 22,
            ),
            IconButton(
              onPressed: () {
                bottomController.currentIndex.value=3;
              },
              icon: Image.asset("assets/images/bottom_profile.png",scale: 2,),
            ),
          ],
        ),
      ),
    );
  }
}
