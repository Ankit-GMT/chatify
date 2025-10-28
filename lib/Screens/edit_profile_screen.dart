import 'package:chatify/Screens/settings_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/widgets/dialog_textfield.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:chatify/widgets/profile_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.put(ProfileController());

    var firstNameController = TextEditingController(
        text: "${profileController.user.value?.firstName}");
    var lastNameController = TextEditingController(
        text: "${profileController.user.value?.lastName}");
    var dobController = TextEditingController(
        text: "${profileController.user.value?.dateOfBirth}");
    var emailController =
        TextEditingController(text: "${profileController.user.value?.email}");
    var aboutController =
        TextEditingController(text: "${profileController.user.value?.about}");

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: Get.height * 0.05,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 43,
                ),
                Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        onTap: () {
                          Get.to(() => SettingsScreen());
                        },
                        child: Text("Settings"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          authController.logoutUser();
                        },
                        child: Text("Logout"),
                      ),
                    ];
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                spacing: 20,
                children: [
                  SizedBox(height: Get.height * 0.01),
                  Stack(
                    children: [
                      Obx(
                        () => profileController.pickedImage.value != null
                            ? CircleAvatar(
                                radius: 56,
                                backgroundImage: FileImage(
                                    profileController.pickedImage.value!),
                              )
                            : ProfileAvatar(
                                imageUrl:
                                    "${profileController.user.value?.profileImageUrl}",
                                radius: 56),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            profileController.showPickerBottomSheet();
                          },
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.primary,
                            child: Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1,
                                      color: Get.isDarkMode
                                          ? AppColors.black
                                          : AppColors.white),
                                  shape: BoxShape.circle),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Get.isDarkMode
                                    ? AppColors.black
                                    : AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: Get.height * 0.01,
                  ),
                  Obx(
                    () => ProfileTile(
                      title: "Name",
                      subtitle:
                          "${profileController.user.value?.firstName} ${profileController.user.value?.lastName}",
                      image: "assets/images/profile_name.png",
                      onTap: () {
                        showDialog(
                          // barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Edit Name"),
                              content: Column(
                                spacing: 10,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: firstNameController,
                                    decoration: InputDecoration(
                                      labelText: "First Name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  TextField(
                                    controller: lastNameController,
                                    decoration: InputDecoration(
                                      labelText: "Last Name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () async {
                                      ChatUser updatedUser = ChatUser(
                                        firstName:
                                            firstNameController.text.trim(),
                                        lastName:
                                            lastNameController.text.trim(),
                                      );

                                      bool success = await profileController
                                          .editProfile(updatedUser);

                                      if (success) {
                                        Get.snackbar("Success", "Name updated");
                                      } else {
                                        Get.snackbar(
                                            "Error", "Failed to update name");
                                      }
                                      profileController.fetchUserProfile();
                                      Navigator.pop(context);
                                    },
                                    child: Text("Update"))
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Obx(
                    () => ProfileTile(
                      title: "Phone Number",
                      subtitle:
                          "+91 ${profileController.user.value?.phoneNumber}",
                      image: "assets/images/profile_phone.png",
                      edit: false,
                      onTap: () {},
                    ),
                  ),
                  Obx(
                    () => ProfileTile(
                      title: "Date of Birth",
                      subtitle: "${profileController.user.value?.dateOfBirth}",
                      image: "assets/images/profile_dob.png",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Edit Date of Birth"),
                              content: TextField(
                                controller: dobController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );

                                  if (pickedDate != null) {
                                    // format date as YYYY-MM-DD
                                    String formattedDate = "${pickedDate.year}-"
                                        "${pickedDate.month.toString().padLeft(2, '0')}-"
                                        "${pickedDate.day.toString().padLeft(2, '0')}";

                                    dobController.text =
                                        formattedDate; // save to controller
                                  }
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    ChatUser updatedUser = ChatUser(
                                      dateOfBirth: dobController.text.trim(),
                                    );

                                    bool success = await profileController
                                        .editProfile(updatedUser);

                                    if (success) {
                                      Get.snackbar("Success", "DOB updated");
                                    } else {
                                      Get.snackbar(
                                          "Error", "Failed to update dob");
                                    }
                                    profileController.fetchUserProfile();
                                    Navigator.pop(context);
                                  },
                                  child: Text("Update"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Obx(
                    () => ProfileTile(
                        title: "Email",
                        image: "assets/images/profile_email.png",
                        onTap: () {
                          Dialogs.editProfile(
                              context, emailController, "Email", () async {
                            ChatUser updatedUser = ChatUser(
                              email: emailController.text.trim(),
                            );

                            bool success = await profileController
                                .editProfile(updatedUser);

                            if (success) {
                              Get.snackbar("Success", "Email updated");
                            } else {
                              Get.snackbar("Error", "Failed to update email");
                            }
                            profileController.fetchUserProfile();
                            Navigator.pop(context);
                          });
                        },
                        subtitle: "${profileController.user.value?.email}"),
                  ),
                  Obx(
                    () => ProfileTile(
                        title: "About",
                        image: "assets/images/setting_about.png",
                        onTap: () {
                          Dialogs.editProfile(
                              context, aboutController, "About", () async {
                            ChatUser updatedUser = ChatUser(
                              about: aboutController.text.trim(),
                            );

                            bool success = await profileController
                                .editProfile(updatedUser);

                            if (success) {
                              Get.snackbar("Success", "About updated");
                            } else {
                              Get.snackbar("Error", "Failed to update about");
                            }
                            profileController.fetchUserProfile();

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          });
                        },
                        subtitle: "${profileController.user.value?.about}"),
                  ),
                  // Text(
                  //   "Version 1.0.0",
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  IconButton(
                    onPressed: () {
                      authController.logoutUser();
                    },
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
