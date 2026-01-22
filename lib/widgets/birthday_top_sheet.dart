import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class BirthdayTopSheet extends StatelessWidget {
  final List<Map<String, dynamic>> birthdayUsers;
  final String title;
  final bool isMultiple;

  const BirthdayTopSheet(
      {super.key,
      required this.birthdayUsers,
      required this.isMultiple,
      required this.title});

  @override
  Widget build(BuildContext context) {
    final msgController =
        TextEditingController(text: "Happy Birthday to you...");
    final tabController = Get.find<TabBarController>();

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                  "assets/images/birthday_bg.png",
                  fit: BoxFit.cover,
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
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.02,
                ),
                Container(
                  width: Get.width * 0.65,
                  height: Get.height * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), // glass effect
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      width: 1.5,
                      color: Color(0xFFECECEC),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    child: TextField(
                      controller: msgController,
                      cursorColor: AppColors.black,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Happy Birthday...",
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Get.height * 0.01),
                if (isMultiple)
                  SizedBox(
                    height: Get.height * 0.12,
                    width: Get.width * 0.66,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: birthdayUsers.length,
                      itemBuilder: (context, index) {
                        final user = birthdayUsers[index];
                        return BirthdayUserTile(
                          name: user["fullName"],
                          image: user["profilePhoto"],
                          onTap: tabController.isLoading4.value
                              ? null
                              : () async {
                                  // print("Tapped userId: ${user["userId"]}");
                                  if (msgController.text.isNotEmpty) {
                                    await tabController
                                        .sendBirthdayMessage(
                                            recipientUserId: user["userId"],
                                            message: msgController.text.trim());
                                    // Get.back();
                                  } else {
                                    Get.snackbar(
                                        "Empty", "Please enter a message");
                                  }
                                },
                        );
                      },
                    ),
                  ),
                if (isMultiple)
                  SizedBox(
                    height: Get.height * 0.01,
                  ),
                InkWell(
                  onTap: tabController.isLoading5.value
                      ? null
                      : () async {
                          if (msgController.text.isNotEmpty) {
                            await tabController.sendBirthdayMessageToAll(
                                recipientUserIds: birthdayUsers
                                    .map((user) => user["userId"] as int)
                                    .toList(),
                                message: msgController.text.trim());
                            if(context.mounted){
                              Navigator.pop(context);
                            }
                          } else {
                            Get.snackbar("Empty", "Please enter a message");
                          }
                        },
                  child: Obx(
                    () => tabController.isLoading5.value
                        ? SizedBox(
                            height: 40,
                            child: Center(child: CircularProgressIndicator()))
                        : Image.asset(
                            'assets/images/birthday_send.png',
                            scale: 1.9,
                          ),
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

class BirthdayUserTile extends StatelessWidget {
  final String name;
  final String image;
  final Future<void> Function()? onTap;

  const BirthdayUserTile({
    super.key,
    required this.name,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Get.width * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(image),
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person),
            ),

            const SizedBox(width: 10),

            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const Spacer(),

            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xffFF512F), Color(0xffF09819)],
                ),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
