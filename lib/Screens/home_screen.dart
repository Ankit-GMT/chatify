import 'package:chatify/Screens/broadcast/broadcast_screen.dart';
import 'package:chatify/Screens/broadcast/scheduled_broadcasts_list_screen.dart';
import 'package:chatify/Screens/create_group_screen.dart';
import 'package:chatify/Screens/edit_profile_screen.dart';
import 'package:chatify/Screens/settings_screen.dart';
import 'package:chatify/TabView%20Screens/all_chats.dart';
import 'package:chatify/TabView%20Screens/contacts_screen.dart';
import 'package:chatify/TabView%20Screens/group_chats.dart';
import 'package:chatify/TabView%20Screens/unread_chats.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/birthday_controller.dart';
import 'package:chatify/controllers/broadcast_controller.dart';
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 5,
                          children: [
                            FloatingActionButton(
                              heroTag: null,
                              backgroundColor: themeController.isDarkMode.value
                                  ? AppColors.white
                                  : AppColors.black,
                              child: Icon(
                                Icons.schedule,
                                color: themeController.isDarkMode.value
                                    ? AppColors.black
                                    : AppColors.white,
                              ),
                              onPressed: () {
                                openBroadcastBottomSheet(context);
                              },
                            ),
                            GestureDetector(
                              onLongPressStart: (_) =>
                                  tabController.startRecording(),
                              onLongPressEnd: (_) =>
                                  tabController.stopRecording(),
                              child: FloatingActionButton(
                                heroTag: null,
                                backgroundColor:
                                    themeController.isDarkMode.value
                                        ? AppColors.white
                                        : AppColors.black,
                                child: Obx(
                                  () => tabController.isRecording.value
                                      ? Icon(
                                          Icons.stop,
                                          color:
                                              themeController.isDarkMode.value
                                                  ? AppColors.black
                                                  : AppColors.white,
                                        )
                                      : Image.asset(
                                          "assets/images/profile_voice.png",
                                          scale: 3,
                                          color:
                                              themeController.isDarkMode.value
                                                  ? AppColors.black
                                                  : AppColors.white,
                                        ),
                                  //     Icon(
                                  //   Icons.stop : Icons.mic,
                                  //   color: tabController.isRecording.value ? Colors.red : (themeController.isDarkMode.value ? Colors.black : Colors.white),
                                  // )
                                ),
                                onPressed: () {
                                  CustomSnackbar.normal(
                                      "Record", "Long press to start recording");
                                },
                              ),
                            ),
                          ],
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
                            // IconButton(
                            //   onPressed: () {
                            //     birthdayController.handleSelfBirthdayFromApi(
                            //         25, "Alex");
                            //   },
                            //   icon: Icon(Icons.account_circle),
                            // ),
                            birthdayController.listBirthdays.isNotEmpty
                                ?
                            GestureDetector(
                                    onTap: () {
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

  //For scheduled broadcast

  void openBroadcastBottomSheet(BuildContext context) {
    final BroadCastController controller = Get.put(BroadCastController());

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,
      // isDismissible: false,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const Text(
                      "Broadcast Message",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 12),

                    /// MESSAGE FIELD (KEYBOARD SAFE)
                    TextField(
                      controller: controller.messageController,
                      // autofocus: true,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Message",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// DATE + TIME
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    controller.selectedDate.value = date;
                                  }
                                },
                                child: _dateTimeBox(
                                  text: controller.selectedDate.value == null
                                      ? "Select Date"
                                      : controller.selectedDate.value!
                                          .toString()
                                          .split(' ')
                                          .first,
                                  icon: Icons.calendar_today,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    controller.selectedTime.value = time;
                                  }
                                },
                                child: _dateTimeBox(
                                  text: controller.selectedTime.value == null
                                      ? "Select Time"
                                      : controller.selectedTime.value!
                                          .format(context),
                                  icon: Icons.access_time,
                                ),
                              ),
                            ),
                          ],
                        )),

                    const SizedBox(height: 20),

                    /// SEND BUTTON (ALWAYS VISIBLE)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            foregroundColor: AppColors.white),
                        onPressed: () {
                          if (controller.messageController.text
                              .trim()
                              .isEmpty) {
                            CustomSnackbar.error("Error", "Message cannot be empty");
                            return;
                          }
                          if (controller.selectedDate.value == null || controller.selectedTime.value == null) {
                            CustomSnackbar.error("Error", "Date & Time cannot be empty");
                            return;
                          }
                          controller.scheduledAt.value = DateTime(
                            controller.selectedDate.value!.year,
                            controller.selectedDate.value!.month,
                            controller.selectedDate.value!.day,
                            controller.selectedTime.value!.hour,
                            controller.selectedTime.value!.minute,
                          );
                          controller.content.value = controller.messageController.text.trim();

                          Get.back();
                          openContactSelectionSheet(context);
                        },
                        child: const Text(
                          "Send",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // CLEAR EVERYTHING WHEN SHEET CLOSES
      controller.messageController.clear();
      controller.selectedDate.value = null;
      controller.selectedTime.value = null;
    });
  }

  void openContactSelectionSheet(BuildContext context) {
    final BroadCastController controller = Get.find<BroadCastController>();
    final tabController = Get.find<TabBarController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8, // 80% height
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

                /// Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Select Contacts & Groups",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Contacts",style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                /// CONTACT LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: tabController.registeredUsers.length,
                    itemBuilder: (_, index) {
                      final user = tabController.registeredUsers[index];
                      return Obx(() {
                        final selected =
                            controller.selectedUserIds.contains(user.userId);
                        return ListTile(
                          onTap: () => controller.toggleUser(user.userId!),
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(user.profileImageUrl ?? ''),
                          ),
                          title: Text("${user.firstName} ${user.lastName}"),
                          trailing: selected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.circle_outlined),
                        );
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        // indent: 20,
                        // endIndent: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Groups",style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        // indent: 20,
                        // endIndent: 20,
                      ),
                    ),
                  ],
                ),
                Expanded(
                    child: ListView.builder(
                      itemCount: tabController.groupChats.length,
                      itemBuilder: (context, index) {
                        final chat = tabController.groupChats[index];
                        return Obx(
                              () {
                            final isSelected =
                            controller.selectedGroupIds.contains(chat.id);
                            return ListTile(
                              onTap: () => controller.toggleGroup(chat.id!),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(chat.groupImageUrl ?? ''),
                              ),
                              title: Text("${chat.name}"),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: Colors.green)
                                  : Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),
                              tileColor:
                              isSelected ? Colors.green.withValues(alpha: 0.1) : null,
                            );
                          },
                        );
                      },
                    )),

                /// CONFIRM BUTTON
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            foregroundColor: AppColors.white),
                        onPressed: controller.selectedUserIds.isEmpty && controller.selectedGroupIds.isEmpty
                            ? null
                            : () {
                                controller.sendScheduledBroadcast(
                                  scheduledAt: controller.scheduledAt.value!,
                                  content:
                                      controller.content.value,
                                  recipientIds:
                                      controller.selectedUserIds.toList(),
                                  groupIds: controller.selectedGroupIds.toList(),
                                );
                              },
                        child: const Text("Confirm & Send"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dateTimeBox({required String text, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
