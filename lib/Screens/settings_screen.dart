import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          spacing: 20,
          children: [
            SizedBox(height: Get.height * 0.01),
            Container(
              height: 85,
              // padding: EdgeInsets.symmetric(horizontal: Get.width * 0.06),
              decoration: BoxDecoration(
                  // color: Color(0xff2A2A2A),
                  borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: (){
                        Get.back();
                      }, icon: Icon(Icons.arrow_back),),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d"),
                      ),
                      SizedBox(
                        width: Get.width * 0.03,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ankit Patel",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: AppColors.black),
                          ),
                          Text(
                            "Online",
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                              color: AppColors.black.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    onPressed: () {},
                    icon: Image.asset(
                      "assets/images/notification_logo.png",
                      scale: 4,
                    ),
                  ),
                ],
              ),
            ),
            CustomTile(
              title: "Edit Profile",
              image: "assets/images/setting_profile.png",
              onTap: () {},
            ),
            CustomTile(
              title: "Change Theme",
              image: "assets/images/setting_theme.png",
              onTap: () {},
            ),
            CustomTile(
              title: "About Us",
              image: "assets/images/setting_about.png",
              onTap: () {},
            ),
            CustomTile(
              title: "Contact Us",
              image: "assets/images/setting_contact.png",
              onTap: () {},
            ),
            CustomTile(
              title: "Privacy Policy",
              image: "assets/images/setting_privacy.png",
              onTap: () {},
            ),
            CustomTile(
              title: "Support",
              image: "assets/images/setting_support.png",
              onTap: () {},
            ),
            CustomTile(
              title: "Invite",
              image: "assets/images/setting_invite.png",
              onTap: () {},
            ),
            Text("Version 1.0.0",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.black.withAlpha(100)),textAlign: TextAlign.center,),
          ],
        ),
      ),
    );
  }
}
