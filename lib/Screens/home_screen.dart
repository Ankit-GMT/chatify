import 'package:chatify/Screens/group_profile_screen.dart';
import 'package:chatify/TabView%20Screens/all_chats.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/tab_controller.dart';
import 'package:chatify/widgets/tab_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {

  final tabController = Get.put(TabBarController());
  // final List<String> tabList = ["All Chat", "Groups", "Contacts"];
   HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: [
          Row(
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
                  backgroundColor: WidgetStatePropertyAll(AppColors.white),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                onPressed: () {
                  Get.to(()=> GroupProfileScreen());
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
            backgroundColor: WidgetStatePropertyAll(Color(0xfff4f4f4)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10),
            ),
            textStyle: WidgetStatePropertyAll(TextStyle(color: AppColors.black),),
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
              child:
              Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBox(
                    tabName: "All Chat",
                    onTap: () {
                      tabController.currentIndex.value=0;
                    },
                    isSelected: tabController.currentIndex.value == 0 ? true : false,
                  ),
                  TabBox(
                    tabName: "Groups",
                    onTap: () {
                      tabController.currentIndex.value = 1;
                    },
                    isSelected: tabController.currentIndex.value == 1 ? true : false,
                  ),
                  TabBox(
                    tabName: "Contacts",
                    onTap: () {
                      tabController.currentIndex.value = 2;
                    },
                    isSelected: tabController.currentIndex.value == 2 ? true : false,
                  ),
                ],
              ),),
            ),
          ),
          SizedBox(
            height: Get.height * 0.01,
          ),
          Expanded(
            child:
            Obx(() => IndexedStack(
              index: tabController.currentIndex.value,
              children: [
                AllChats(),
                Center(
                  child: Text("Groups"),
                ),
                Center(
                  child: Text("Contacts"),
                ),
              ],
            ),)
          ),
        ],
      ),
    );
  }
}
