import 'package:chatify/Screens/broadcast/broadcast_screen.dart';
import 'package:chatify/Screens/broadcast/scheduled_broadcasts_list_screen.dart';
import 'package:chatify/Screens/broadcast/voice_broadcast_screen.dart';
import 'package:chatify/Screens/create_group_screen.dart';
import 'package:chatify/Screens/edit_profile_screen.dart';
import 'package:chatify/Screens/settings_screen.dart';
import 'package:chatify/Screens/voice_recorder_screen.dart';
import 'package:chatify/TabView%20Screens/all_chats.dart';
import 'package:chatify/TabView%20Screens/contacts_screen.dart';
import 'package:chatify/TabView%20Screens/group_chats.dart';
import 'package:chatify/TabView%20Screens/unread_chats.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/birthday_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/widgets/tab_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  final tabController = Get.put(TabBarController());
  final profileController = Get.put(ProfileController());
  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();
  final birthdayController = Get.find<BirthdayController>();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx(
        () => Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: tabController.currentIndex.value == 2
              ? FloatingActionButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    Get.to(() => CreateGroupScreen(
                        currentUserId: profileController.user.value!.id!));
                  },
                  child: Icon(
                    Icons.add,
                    color: AppColors.white,
                  ),
                )
              : tabController.currentIndex.value == 0
                  ? Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        // Visual Indicator (Shows above the button when recording)
                        Obx(() => tabController.isRecording.value
                            ? Positioned(
                                bottom: 70,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.fiber_manual_record,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 5),
                                      Text(
                                          "Recording ${tabController.recordDuration.value}s",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox.shrink()),

                        // The Button
                        GestureDetector(
                          onLongPressStart: (_) =>
                              tabController.startRecording(),
                          onLongPressEnd: (_) => tabController.stopRecording(),
                          child: FloatingActionButton(
                            backgroundColor: themeController.isDarkMode.value
                                ? AppColors.white
                                : AppColors.black,
                            child: Obx(
                              () => tabController.isRecording.value
                                  ? Icon(
                                      Icons.stop,
                                      color: themeController.isDarkMode.value
                                          ? AppColors.black
                                          : AppColors.white,
                                    )
                                  : Image.asset(
                                      "assets/images/profile_voice.png",
                                      scale: 3,
                                      color: themeController.isDarkMode.value
                                          ? AppColors.black
                                          : AppColors.white,
                                    ),
                              //     Icon(
                              //   Icons.stop : Icons.mic,
                              //   color: tabController.isRecording.value ? Colors.red : (themeController.isDarkMode.value ? Colors.black : Colors.white),
                              // )
                            ),
                            onPressed: () {
                              Get.snackbar(
                                  "Record", "Long press to start recording",
                                  backgroundColor: AppColors.primary,
                                  colorText: AppColors.white);
                            },
                          ),
                        ),
                      ],
                    )
                  // FloatingActionButton(
                  //             backgroundColor:
                  //                 themeController.isDarkMode.value ? AppColors.white : AppColors.black,
                  //             // foregroundColor: Get.isDarkMode ?AppColors.black: AppColors.white,
                  //             child: Image.asset(
                  //               "assets/images/profile_voice.png",
                  //               scale: 3,
                  //               color:
                  //               themeController.isDarkMode.value ? AppColors.black : AppColors.white,
                  //             ),
                  //             onPressed: () async {
                  //               final result =
                  //                   await Get.to(() => const VoiceRecorderScreen());
                  //
                  //               if (result != null) {
                  //                 Get.to(
                  //                   () => VoiceBroadcastScreen(),
                  //                   arguments: {
                  //                     "path": result["path"],
                  //                     "duration": result["duration"],
                  //                   },
                  //                 );
                  //               }
                  //             },
                  //           )
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
              tabController.isSelectionMode.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: tabController.clearSelection,
                            ),
                            Text(
                              "${tabController.selectedChats.length} selected",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Wrap(
                          children: [
                            // IconButton(
                            //   icon: Icon(
                            //     Icons.push_pin,
                            //   ),
                            //   onPressed: () {
                            //     tabController.pinSelectedChats();
                            //   },
                            // ),
                            IconButton(
                              icon: Icon(
                                tabController.areAllSelectedPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                              ),
                              onPressed: () {
                                if (tabController.areAllSelectedPinned) {
                                  tabController.unPinSelectedChats();
                                } else {
                                  tabController.pinSelectedChats();
                                }
                              },
                            ),
                            // IconButton(
                            //   icon: Icon(tabController.areAllSelectedMuted
                            //       ? Icons.volume_up
                            //       : Icons.volume_off_outlined),
                            //   onPressed: () {
                            //     if (tabController.areAllSelectedMuted) {
                            //       tabController.unMuteSelectedChats();
                            //     } else {
                            //       tabController.muteSelectedChats();
                            //     }
                            //   },
                            // ),
                            // IconButton(
                            //   icon: Icon(Icons.volume_up),
                            //   onPressed: () {
                            //     tabController.unMuteSelectedChats();
                            //   },
                            // ),
                            // IconButton(
                            //   icon: const Icon(Icons.delete_outline),
                            //   onPressed: () {},
                            // ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Messages",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            birthdayController.listBirthdays.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      // GetStorage().remove("birthday_shown");
                                      birthdayController.handleBirthdayFromApi(
                                          birthdayController.listBirthdays);
                                    },
                                    child: Container(
                                      width: Get.width * 0.1,
                                      height: Get.width * 0.1,
                                      decoration: BoxDecoration(
                                          color: AppColors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.grey.shade300,
                                                spreadRadius: 1,
                                                blurRadius: 1),
                                          ]),
                                      child: Center(
                                        child: Icon(
                                          Icons.cake_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(),
                            Container(
                              width: Get.width * 0.1,
                              height: Get.width * 0.1,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey.shade300,
                                      spreadRadius: 1,
                                      blurRadius: 1),
                                ],
                              ),
                              child: Center(
                                child: PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  color: AppColors.white,
                                  iconColor: AppColors.primary,
                                  // iconSize: 26,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),

                                  itemBuilder: (context) {
                                    return [
                                      PopupMenuItem(
                                        onTap: () {
                                          Get.to(() => EditProfileScreen());
                                        },
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              color: AppColors.primary,
                                            ),
                                            Text(
                                              "Profile",
                                              style: TextStyle(
                                                  color: AppColors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          Get.to(() => SettingsScreen());
                                        },
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.settings_outlined,
                                              color: AppColors.primary,
                                            ),
                                            Text(
                                              "Settings",
                                              style: TextStyle(
                                                  color: AppColors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          Get.to(() => BroadcastScreen());
                                        },
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.people_alt_outlined,
                                              color: AppColors.primary,
                                            ),
                                            Text(
                                              "Broadcast Message",
                                              style: TextStyle(
                                                  color: AppColors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          showMediaBroadcastOptions();
                                        },
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.video_library_outlined,
                                              color: AppColors.primary,
                                            ),
                                            Text(
                                              "Media Broadcast Message",
                                              style: TextStyle(
                                                  color: AppColors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          Get.to(() =>
                                              ScheduledBroadcastsListScreen());
                                        },
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.view_list_outlined,
                                              color: AppColors.primary,
                                            ),
                                            Text(
                                              "View Scheduled Broadcasts",
                                              style: TextStyle(
                                                  color: AppColors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          Get.defaultDialog(
                                            title: "Logout",
                                            middleText:
                                                "Are you sure you want to logout?",
                                            textCancel: "No",
                                            textConfirm: "Yes",
                                            confirmTextColor: Colors.white,
                                            buttonColor: AppColors.primary,
                                            titlePadding: EdgeInsets.only(
                                                top: 20, bottom: 10),
                                            contentPadding:
                                                EdgeInsets.only(bottom: 20),
                                            onConfirm: () {
                                              Get.back(); // close dialog
                                              authController.logoutUser();
                                            },
                                          );
                                        },
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.logout,
                                              color: AppColors.primary,
                                            ),
                                            Text(
                                              "Logout",
                                              style: TextStyle(
                                                  color: AppColors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              SearchBar(
                controller: tabController.searchController,
                onChanged: tabController.updateSearch,
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
                // trailing:
                // tabController.searchQuery.value.isNotEmpty
                //     ? [
                //         IconButton(
                //           onPressed: () {
                //             tabController.searchController.clear();
                //             tabController.updateSearch('');
                //           },
                //           icon: Icon(Icons.clear),
                //         ),
                //       ]
                //     : null,
                trailing: [
                  if (tabController.searchQuery.value.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        tabController.searchController.clear();
                        tabController.updateSearch('');
                      },
                      icon: Icon(Icons.clear),
                    )
                  else
                    IconButton(
                      onPressed: () {
                        tabController.isListening.value
                            ? tabController.stopVoiceSearch()
                            : tabController.startVoiceSearch();
                      },
                      icon: Icon(
                        Icons.mic,
                        color: tabController.isListening.value
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                    ),
                ],
                hintText: "Search",
                hintStyle: WidgetStatePropertyAll(TextStyle(
                    // color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
                elevation: WidgetStatePropertyAll(0),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: tabController.isListening.value
                          ? Colors.green
                          : Colors.transparent,
                    ),
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
                    () => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
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
                            tabName: "Unread",
                            onTap: () {
                              tabController.currentIndex.value = 1;
                            },
                            isSelected: tabController.currentIndex.value == 1
                                ? true
                                : false,
                          ),
                          TabBox(
                            tabName: "Groups",
                            onTap: () {
                              tabController.currentIndex.value = 2;
                            },
                            isSelected: tabController.currentIndex.value == 2
                                ? true
                                : false,
                          ),
                          TabBox(
                            tabName: "Contacts",
                            onTap: () {
                              tabController.currentIndex.value = 3;
                            },
                            isSelected: tabController.currentIndex.value == 3
                                ? true
                                : false,
                          ),
                        ],
                      ),
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
                    UnreadChats(),
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

  void showMediaBroadcastOptions() {
    Get.bottomSheet(
      backgroundColor: AppColors.white,
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.image,
                color: AppColors.black,
              ),
              title: Text(
                "Image",
                style: TextStyle(
                  color: AppColors.black,
                ),
              ),
              onTap: () {
                Get.back();
                tabController.pickMediaForBroadcast("IMAGE");
              },
            ),
            ListTile(
              leading: Icon(
                Icons.videocam,
                color: AppColors.black,
              ),
              title: Text(
                "Video",
                style: TextStyle(
                  color: AppColors.black,
                ),
              ),
              onTap: () {
                Get.back();
                tabController.pickMediaForBroadcast("VIDEO");
              },
            ),
            ListTile(
              leading: Icon(
                Icons.insert_drive_file,
                color: AppColors.black,
              ),
              title: Text(
                "Document",
                style: TextStyle(
                  color: AppColors.black,
                ),
              ),
              onTap: () {
                Get.back();
                tabController.pickMediaForBroadcast("DOCUMENT");
              },
            ),
          ],
        ),
      ),
    );
  }
}
