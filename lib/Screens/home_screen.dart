import 'package:chatify/Screens/create_group_screen.dart';
import 'package:chatify/Screens/search_user_screen.dart';
import 'package:chatify/TabView%20Screens/all_chats.dart';
import 'package:chatify/TabView%20Screens/contacts_screen.dart';
import 'package:chatify/TabView%20Screens/group_chats.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/widgets/tab_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  final tabController = Get.put(TabBarController());
  final profileController = Get.put(ProfileController());
  final userController = Get.put(UserController());

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx(
        () => Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: tabController.currentIndex.value == 1
              ? FloatingActionButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    Get.to(() => CreateGroupScreen(
                        currentUserId: profileController.user.value!.id!));
                  },
                  child: Icon(Icons.add),
                )
              : null,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Obx(
          () => Column(
            children: [
              SizedBox(
                height: Get.height * 0.05,
              ),
              userController.isSelectionMode.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: userController.clearSelection,
                            ),
                            Text(
                              "${userController.selectedChats.length} selected",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Wrap(
                          children: [
                            IconButton(
                              icon: Icon(userController.areAllSelectedPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin,),
                              onPressed: userController.togglePinSelected,
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_off_outlined),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Messages",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          color: AppColors.iconGrey,
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(AppColors.white),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side:
                                      BorderSide(color: Colors.grey.shade200)),
                            ),
                          ),
                          onPressed: () {
                            // Get.to(()=> );
                          },
                          icon: Image.asset(
                            "assets/images/notification_logo.png",
                            scale: 4,
                          ),
                        ),
                      ],
                    ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              SearchBar(
                onTap: () {
                  Get.to(() => SearchUserScreen());
                },
                backgroundColor: WidgetStatePropertyAll(Color(0xfff4f4f4)),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 10),
                ),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(color: AppColors.black),
                ),
                leading: Icon(
                  CupertinoIcons.search,
                  color: Colors.grey.shade500,
                ),
                hintText: "Search",
                hintStyle: WidgetStatePropertyAll(TextStyle(
                    // color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
                elevation: WidgetStatePropertyAll(0),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 1,
                    ),
                  ),
                  child: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBox(
                          tabName: "All Chat",
                          onTap: () {
                            tabController.currentIndex.value = 0;
                          },
                          isSelected: tabController.currentIndex.value == 0
                              ? true
                              : false,
                        ),
                        TabBox(
                          tabName: "Groups",
                          onTap: () {
                            tabController.currentIndex.value = 1;
                          },
                          isSelected: tabController.currentIndex.value == 1
                              ? true
                              : false,
                        ),
                        TabBox(
                          tabName: "Contacts",
                          onTap: () {
                            tabController.currentIndex.value = 2;
                          },
                          isSelected: tabController.currentIndex.value == 2
                              ? true
                              : false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Expanded(
                  child: Obx(
                () => IndexedStack(
                  index: tabController.currentIndex.value,
                  children: [
                    AllChats(),
                    GroupChats(),
                    ContactsScreen(),
                  ],
                ),
              )),
              // SizedBox(
              //   height: Get.height * 0.05,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
