import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomBox extends StatelessWidget {
  final String image;
  final String title;
  final Function() onTap;

  const CustomBox(
      {super.key,
      required this.image,
      required this.title,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        height: 70,
        width: Get.width * 0.26,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
                height: 24,
                width: 24,
                child: Image.asset(
                  image,
                  scale: 4,
                )),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
