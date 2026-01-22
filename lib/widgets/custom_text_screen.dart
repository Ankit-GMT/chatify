import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const CustomTextScreen(
      {super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
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
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.arrow_left),
                ),
                SizedBox(width: Get.width * 0.24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Card(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
