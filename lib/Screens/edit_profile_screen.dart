import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/widgets/profile_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          spacing: 20,
          children: [
            SizedBox(height: Get.height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // IconButton(
                //   color: AppColors.iconGrey,
                //   style: ButtonStyle(
                //     backgroundColor: WidgetStatePropertyAll(AppColors.white),
                //     shape: WidgetStatePropertyAll(
                //       RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(20),
                //           side: BorderSide(color: Colors.grey.shade200)),
                //     ),
                //   ),
                //   onPressed: () {
                //     Get.back();
                //   },
                //   icon: Icon(Icons.arrow_left),
                // ),
                // SizedBox(width: Get.width * 0.24),
                Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: Get.height * 0.01),
            Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundImage: NetworkImage("https://picsum.photos/200"),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary,
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1,color: Get.isDarkMode ? AppColors.black : AppColors.white),
                        shape: BoxShape.circle
                      ),
                      child: Icon(Icons.edit_rounded,size: 14,color: Get.isDarkMode? AppColors.black : AppColors.white,),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: Get.height* 0.01,
            ),
            ProfileTile(
              title: "Name",
              subtitle: "Ankit Patel",
              image: "assets/images/profile_name.png",
              onTap: () {},
            ),
            ProfileTile(
              title: "About",
              subtitle: "Hey, I'm using Chatify",
              image: "assets/images/setting_about.png",
              onTap: () {},
            ),
            ProfileTile(
              title: "Phone Number",
              subtitle: "+91 9876543210",
              image: "assets/images/profile_phone.png",
              onTap: () {},
            ),
            Text(
              "Version 1.0.0",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
