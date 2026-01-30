import 'package:chatify/Screens/add_group_members_screen.dart';
import 'package:chatify/Screens/chat_background_picker.dart';
import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/Screens/edit_profile_screen.dart';
import 'package:chatify/Screens/profile_screen.dart';
import 'package:chatify/Screens/view_all_members_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/chat_background_controller.dart';
import 'package:chatify/controllers/group_controller.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/widgets/custom_box.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../controllers/chat_screen_controller.dart';

const int previewLimit = 3;

class GroupProfileScreen extends StatelessWidget {
  const GroupProfileScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final messageController = Get.find<MessageController>();
    final groupController = Get.put(GroupController());
    final tabController = Get.find<TabBarController>();
    final chatController = Get.find<ChatScreenController>();

    final myId = profileController.user.value?.id;

    final chat = chatController.chatType;
    final isAdmin = chat.value!.members
            ?.any((m) => m.userId == myId && m.role == "ADMIN") ??
        false;
    var nameController = TextEditingController(text: "${chat.value!.name}");

    final previewMembers = chat.value!.members?.take(7).toList();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            isAdmin
                ? PopupMenuButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(AppColors.white),
                      foregroundColor:
                          WidgetStatePropertyAll((AppColors.black)),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          onTap: () {
                            groupController.editImage(
                                ImageSource.gallery, chat.value!.id!);
                          },
                          child: Text("Change Group Image"),
                        ),
                        PopupMenuItem(
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
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          labelText: "Group Name",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () async {
                                          await groupController.updateGroup(
                                              groupId: chat.value!.id!,
                                              newName:
                                                  nameController.text.trim());

                                          chatController
                                              .fetchChatType(chat.value!.id!);
                                          Navigator.pop(Get.context!);
                                        },
                                        child: Text("Update"))
                                  ],
                                );
                              },
                            );
                          },
                          child: Text("Change Group Name"),
                        ),
                        if (!chat.value!.locked.value)
                          PopupMenuItem(
                            onTap: () {
                              Get.back();
                              _showSetPinSheet(chat.value!.id!);
                            },
                            child: Row(
                              spacing: 5,
                              children: [
                                Icon(Icons.lock),
                                Text("Lock Chat"),
                              ],
                            ),
                          ),
                        if (chat.value!.locked.value)
                          PopupMenuItem(
                            onTap: () {
                              Get.back();
                              _confirmUnlock(chat.value!.id!, chatController);
                            },
                            child: Row(
                              spacing: 5,
                              children: [
                                Icon(Icons.lock_open),
                                Text("Unlock Chat"),
                              ],
                            ),
                          ),
                      ];
                    },
                  )
                : PopupMenuButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(AppColors.white),
                      foregroundColor:
                          WidgetStatePropertyAll((AppColors.black)),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    itemBuilder: (context) {
                      return [
                        if (!chat.value!.locked.value)
                          PopupMenuItem(
                            onTap: () {
                              Get.back();
                              _showSetPinSheet(chat.value!.id!);
                            },
                            child: Row(
                              spacing: 5,
                              children: [
                                Icon(Icons.lock),
                                Text("Lock Chat"),
                              ],
                            ),
                          ),
                        if (chat.value!.locked.value)
                          PopupMenuItem(
                            onTap: () {
                              Get.back();
                              _confirmUnlock(chat.value!.id!, chatController);
                            },
                            child: Row(
                              spacing: 5,
                              children: [
                                Icon(Icons.lock_open),
                                Text("Unlock Chat"),
                              ],
                            ),
                          ),
                      ];
                    },
                  ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(
            () => Column(
              spacing: 20,
              children: [
                SizedBox(height: Get.height * 0.1),

                GestureDetector(
                    onTap: () {
                      // groupController.editImage(
                      //     ImageSource.gallery, chat.value!.id!);
                    },
                    child: ProfileAvatar(
                        imageUrl: chat.value!.groupImageUrl ?? '', radius: 50)),
                Column(
                  children: [
                    Text(
                      chat.value!.name! ?? '',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "${chat.value!.members!.length.toString()} Members",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomBox(
                      title: "Voice Call",
                      image: "assets/images/profile_voice.png",
                      onTap: () {
                        final channelId = chat.value!.id.toString();
                        debugPrint('StartCAll channel:-   $channelId');
                        final rIds = chat.value?.members
                            ?.map((m) => m.userId)
                            .where((id) => id != myId)
                            .toList();
                        final receiverIds =
                            rIds?.map((id) => id.toString()).toList() ?? [];
                        debugPrint("Start call receiverids:- $receiverIds");
                        messageController.startGroupCall(
                            context: context,
                            channelId: channelId,
                            callerId:
                                profileController.user.value!.id.toString(),
                            callerName: profileController.user.value!.firstName
                                .toString(),
                            isVideo: false,
                            receiverIds: receiverIds,
                            groupId: chat.value!.id!);
                      },
                    ),
                    CustomBox(
                      title: "Video Call",
                      image: "assets/images/profile_video.png",
                      onTap: () {
                        final channelId = chat.value!.id.toString();
                        debugPrint('StartCAll channel:-   $channelId');
                        final rIds = chat.value?.members
                            ?.map((m) => m.userId)
                            .where((id) => id != myId)
                            .toList();
                        final receiverIds =
                            rIds?.map((id) => id.toString()).toList() ?? [];
                        debugPrint("Start call receiverids:- $receiverIds");
                        messageController.startGroupCall(
                            context: context,
                            channelId: channelId,
                            callerId:
                                profileController.user.value!.id.toString(),
                            callerName: profileController.user.value!.firstName
                                .toString(),
                            isVideo: true,
                            receiverIds: receiverIds,
                            groupId: chat.value!.id!);
                      },
                    ),
                    CustomBox(
                      title: "Add ",
                      image: "assets/images/profile_addUser.png",
                      onTap: () {
                        Get.to(() => AddGroupMembersScreen(
                              groupId: chat.value!.id!,
                            ));
                        groupController.loadCurrentMembers(chat.value!.members!
                            .map((e) => e.userId!)
                            .toList());
                      },
                    ),
                  ],
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Media",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    padding: EdgeInsets.only(left: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        height: 70,
                        width: 70,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              "https://picsum.photos/200/300",
                              fit: BoxFit.cover,
                            )),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Group Members",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(() => ViewAllMembersScreen(
                              chatType: chat.value,
                            ));
                      },
                      child: Text(
                        "View All",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey),
                      ),
                    ),
                  ],
                ),
                // SizedBox(
                //   height: 250,
                //   child: ListView.separated(
                //       shrinkWrap: true,
                //       padding: EdgeInsets.zero,
                //       itemCount: chat.value!.members!.length,
                //       scrollDirection: Axis.vertical,
                //       itemBuilder: (context, index) {
                //         return ListTile(
                //           onTap: () {
                //
                //           },
                //           onLongPress: (chat.value!.members![index].role ==
                //                       "MEMBER" &&
                //                   isAdmin)
                //               ? () {
                //                   Get.defaultDialog(
                //                     title: "Remove user",
                //                     middleText:
                //                         "Are you sure you want to Remove ${chat.value!.members![index].firstName} ${chat.value!.members![index].lastName}?",
                //                     textCancel: "No",
                //                     textConfirm: "Yes",
                //                     confirmTextColor: Colors.white,
                //                     buttonColor: AppColors.primary,
                //                     titlePadding:
                //                         EdgeInsets.only(top: 20, bottom: 10),
                //                     contentPadding: EdgeInsets.only(
                //                         bottom: 20, left: 10, right: 10),
                //                     onConfirm: () async {
                //                       await groupController.removeMember(
                //                           groupId: chat.value!.id!,
                //                           memberId: chat
                //                               .value!.members![index].userId!);
                //                       chatController.fetchChatType(chat.value!.id!);
                //                     },
                //                   );
                //                 }
                //               : null,
                //           leading: CircleAvatar(
                //             // radius: 25,
                //             backgroundImage: NetworkImage(
                //                 chat.value!.members![index].profileImageUrl ??
                //                     ''),
                //           ),
                //           title: Text(
                //               "${chat.value!.members![index].firstName} ${chat.value!.members![index].lastName}"),
                //           subtitle: Text(
                //             chat.value!.members![index].role!,
                //             style: TextStyle(fontSize: 12),
                //           ),
                //         );
                //       },
                //       separatorBuilder: (context, index) {
                //         return Divider(
                //           thickness: 0.5,
                //           indent: 15,
                //           endIndent: 15,
                //         );
                //       }),
                // ),
                Column(
                  children: [
                    ...chat.value!.members!.take(previewLimit).map(
                          (member) => ListTile(
                            onTap: member.userId != myId
                                ? () {
                                    if (member.privateChatId != null) {
                                      chatController
                                          .fetchChatType(member.privateChatId!);
                                      Get.to(() => ProfileScreen(
                                            id: member.userId,
                                            isFromGroup: true,
                                            groupChatId: chat.value!.id!,
                                          ));
                                    }
                                    print(member.privateChatId);
                                  }
                                : () {
                                    Get.to(() => EditProfileScreen());
                                  },
                            onLongPress: (member.role == "MEMBER" && isAdmin)
                                ? () {
                                    Get.defaultDialog(
                                      title: "Remove user",
                                      titlePadding: EdgeInsets.only(
                                        bottom: Get.height * 0.02,
                                        top: Get.width * 0.02,
                                      ),
                                      contentPadding: EdgeInsets.only(
                                        bottom: Get.height * 0.02,
                                        left: Get.width * 0.02,
                                        right: Get.width * 0.02,
                                      ),
                                      middleText:
                                          "Are you sure you want to remove\n${member.firstName} ${member.lastName} ?",
                                      textCancel: "No",
                                      textConfirm: "Yes",
                                      confirmTextColor: Colors.white,
                                      buttonColor: AppColors.primary,
                                      onConfirm: () async {
                                        await groupController.removeMember(
                                          groupId: chat.value!.id!,
                                          memberId: member.userId!,
                                        );
                                        chatController
                                            .fetchChatType(chat.value!.id!);
                                      },
                                    );
                                  }
                                : null,
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(member.profileImageUrl ?? ""),
                            ),
                            title: Text(
                              "${member.firstName} ${member.lastName}",
                            ),
                            subtitle: Text(
                              member.role ?? "",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    if (chat.value!.members!.length > previewLimit)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InkWell(
                          onTap: () {
                            Get.to(() => ViewAllMembersScreen(
                                  chatType: chat.value,
                                ));
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "View all ${chat.value!.members!.length} members",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                CustomTile(
                  title: "Change Chat Background",
                  image: "assets/images/profile_wallpaper.png",
                  onTap: () {
                    Get.to(
                      () => ChatWallpaperPicker(chatId: chat.value!.id!),
                      binding: BindingsBuilder(() {
                        Get.put(ChatBackgroundController(chat.value!.id!));
                      }),
                    );
                  },
                ),
                CustomTile(
                  title: "Notification",
                  image: "assets/images/profile_notification.png",
                  onTap: () {},
                ),
                // isAdmin
                //     ? SizedBox()
                //     : CustomTile(
                //         title: "Exit Group",
                //         image: "assets/images/profile_exit.png",
                //         onTap: () async {
                //           await groupController.exitGroup(groupId: chat.value!.id!);
                //           await tabController.getAllChats();
                //         },
                //       ),
                isAdmin
                    ? ListTile(
                        onTap: () async {
                          await groupController.deleteGroup(
                              groupId: chat.value!.id!);
                          await tabController.getAllChats();
                        },
                        minTileHeight: 60,
                        tileColor: AppColors.settingTile.withAlpha(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: SizedBox(
                            height: 25,
                            width: 25,
                            child: Icon(
                              Icons.delete_forever,
                              color: AppColors.primary,
                            )),
                        title: Text(
                          "Delete Group",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.primary, size: 15),
                      )
                    : CustomTile(
                        title: "Exit Group",
                        image: "assets/images/profile_exit.png",
                        onTap: () async {
                          await groupController.exitGroup(
                              groupId: chat.value!.id!);
                          await tabController.getAllChats();
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
        ),
      ),
    );
  }

  void _showSetPinSheet(int chatId) {
    String? pin;
    String? confirmPin;

    final chatController = Get.find<ChatScreenController>();

    showDialog(
        context: Get.context!,
        builder: (_) {
          return Dialog(
            backgroundColor: AppColors.black,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Set a 4-digit PIN to lock this chat",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: Get.height * 0.03),
                  Text(
                    "Create Pin",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white),
                  ),
                  SizedBox(height: Get.height * 0.02),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Get.width * 0.1),
                    child: PinCodeTextField(
                      appContext: Get.context!,
                      length: 4,
                      textStyle: TextStyle(color: Colors.black),
                      obscureText: true,
                      onChanged: (value) {
                        pin = value;
                      },
                      onCompleted: (value) {
                        debugPrint("OTP Entered: $value");
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.black,
                      cursorWidth: 0.5,
                      showCursor: true,
                      cursorHeight: 15,
                      autoFocus: true,
                      pinTheme: PinTheme(
                        fieldOuterPadding: EdgeInsets.symmetric(horizontal: 10),
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        activeColor: Colors.grey.shade400,
                        inactiveColor: Colors.grey.shade300,
                        selectedColor: AppColors.primary,
                        activeBoxShadow: [
                          BoxShadow(
                            color: Color(0xff63636333).withAlpha(51),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      enableActiveFill: true,
                    ),
                  ),
                  SizedBox(height: Get.height * 0.01),
                  Text(
                    "Confirm Pin",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white),
                  ),
                  SizedBox(height: Get.height * 0.02),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Get.width * 0.1),
                    child: PinCodeTextField(
                      appContext: Get.context!,
                      length: 4,
                      textStyle: TextStyle(color: Colors.black),
                      obscureText: true,
                      onChanged: (value) {
                        confirmPin = value;
                      },
                      onCompleted: (value) {
                        debugPrint("OTP Entered: $value");
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.black,
                      cursorWidth: 0.5,
                      showCursor: true,
                      cursorHeight: 15,
                      autoFocus: true,
                      pinTheme: PinTheme(
                        fieldOuterPadding: EdgeInsets.symmetric(horizontal: 10),
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        activeColor: Colors.grey.shade400,
                        inactiveColor: Colors.grey.shade300,
                        selectedColor: AppColors.primary,
                        activeBoxShadow: [
                          BoxShadow(
                            color: Color(0xff63636333).withAlpha(51),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      enableActiveFill: true,
                    ),
                  ),
                  SizedBox(height: Get.height * 0.02),
                  SizedBox(
                    width: Get.width * 0.6,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () async {
                        if (pin?.length != 4) {
                          CustomSnackbar.error("Error", "PIN must be 4 digits");
                          return;
                        }

                        if (pin != confirmPin) {
                          CustomSnackbar.error("Error", "PINs do not match");
                          return;
                        }

                        await chatController.lockChat(
                          chatId: chatId.toString(),
                          pin: pin!,
                        );
                      },
                      child: const Text("Lock Chat"),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void _confirmUnlock(int chatId, ChatScreenController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text("Remove Chat Lock?"),
        content: const Text(
          "This chat will no longer be protected by a PIN.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              controller.unlockChat(chatId: chatId.toString());
            },
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }
}
