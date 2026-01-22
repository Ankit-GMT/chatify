import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/widgets/custom_text_screen.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          spacing: 20,
          children: [
            SizedBox(height: Get.height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  color: AppColors.iconGrey,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(AppColors.white),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.arrow_left),
                ),
                SizedBox(width: Get.width * 0.26),
                Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: Get.height * 0.02,
            ),
            // CustomTile(
            //   title: "Edit Profile",
            //   image: "assets/images/setting_profile.png",
            //   onTap: () {},
            // ),
            CustomTile(
              title: "Dark Theme",
              image: "assets/images/setting_theme.png",
              onTap: () {},
              isTheme: true,
              icon: Obx(
                () => Switch(
                  activeThumbColor: AppColors.primary,
                  inactiveThumbColor: AppColors.primary,
                  value: themeController.isDarkMode.value,
                  onChanged: (value) {
                    themeController.toggleTheme();
                  },
                ),
              ),
            ),
            CustomTile(
              title: "About Us",
              image: "assets/images/setting_about.png",
              onTap: () {
                Get.to(CustomTextScreen(title: "About Us", content: aboutUs));
              },
            ),
            CustomTile(
              title: "Contact Us",
              image: "assets/images/setting_contact.png",
              onTap: () {
                Get.to(CustomTextScreen(title: "Contact Us", content: aboutUs));
              },
            ),
            CustomTile(
              title: "Privacy Policy",
              image: "assets/images/setting_privacy.png",
              onTap: () {
                Get.to(CustomTextScreen(title: "Privacy Policy", content: privacyPolicy));
              },
            ),
            CustomTile(
              title: "Terms and Conditions",
              image: "assets/images/setting_terms.png",
              onTap: () {
                Get.to(CustomTextScreen(title: "Terms and Conditions", content: terms));
              },
            ),
            CustomTile(
              title: "Invite",
              image: "assets/images/setting_invite.png",
              onTap: () {
                if (kIsWeb) {
                  Get.snackbar('Not supported', 'Sharing is not supported on web');
                } else {
                  Share.share(
                    'Check out Chatify https://example.com',
                    subject: 'Chatify',
                  );
                }
              },
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
