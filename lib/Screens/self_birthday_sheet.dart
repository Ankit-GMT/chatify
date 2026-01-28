import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SelfBirthdaySheet extends StatelessWidget {
  final int age;
  final String firstName;

  const SelfBirthdaySheet(
      {super.key,
        required this.age,
        required this.firstName
      });

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.48,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(50),
              bottomLeft: Radius.circular(50)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(50),
                    bottomLeft: Radius.circular(50)),
                child: Image.asset(
                  "assets/images/self_birthday.png",
                  fit: BoxFit.cover
                  ,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: Get.height * 0.15,
                  width: Get.width,
                ),
                Text(
                  "Happy Birthday, $firstName",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.005,
                ),
                Text(
                  " Let the celebrations begin it’s your moment today",
                  // overflow: TextOverflow.ellipsis,
                  // maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    letterSpacing: 1.2,
                  ),
                ),

              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  "assets/animations/Confetti.json",
                  fit: BoxFit.cover,
                  repeat: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

