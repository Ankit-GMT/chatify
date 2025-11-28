import 'package:chatify/Screens/add_group_members_screen.dart';
import 'package:chatify/Screens/view_all_members_screen.dart';
import 'package:chatify/constants/app_colors.dart';
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

import '../controllers/chat_screen_controller.dart';

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
                      ];
                    },
                  )
                : SizedBox(),
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
                        print('StartCAll channel:-   $channelId');
                        final rIds = chat.value?.members
                            ?.map((m) => m.userId)
                            .where((id) => id != myId)
                            .toList();
                        final receiverIds =
                            rIds?.map((id) => id.toString()).toList() ?? [];
                        print("Start call receiverids:- $receiverIds");
                        messageController.startGroupCall(
                            context: context,
                            channelId: channelId,
                            callerId:
                                profileController.user.value!.id.toString(),
                            callerName: profileController.user.value!.firstName
                                .toString(),
                            isVideo: false,
                            receiverIds: receiverIds);
                      },
                    ),
                    CustomBox(
                      title: "Video Call",
                      image: "assets/images/profile_video.png",
                      onTap: () {
                        final channelId = chat.value!.id.toString();
                        print('StartCAll channel:-   $channelId');
                        final rIds = chat.value?.members
                            ?.map((m) => m.userId)
                            .where((id) => id != myId)
                            .toList();
                        final receiverIds =
                            rIds?.map((id) => id.toString()).toList() ?? [];
                        print("Start call receiverids:- $receiverIds");
                        messageController.startGroupCall(
                            context: context,
                            channelId: channelId,
                            callerId:
                                profileController.user.value!.id.toString(),
                            callerName: profileController.user.value!.firstName
                                .toString(),
                            isVideo: true,
                            receiverIds: receiverIds);
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
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: chat.value!.members!.length,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onLongPress: (chat.value!.members![index].role ==
                                      "MEMBER" &&
                                  isAdmin)
                              ? () {
                                  Get.defaultDialog(
                                    title: "Remove user",
                                    middleText:
                                        "Are you sure you want to Remove ${chat.value!.members![index].firstName} ${chat.value!.members![index].lastName}?",
                                    textCancel: "No",
                                    textConfirm: "Yes",
                                    confirmTextColor: Colors.white,
                                    buttonColor: AppColors.primary,
                                    titlePadding:
                                        EdgeInsets.only(top: 20, bottom: 10),
                                    contentPadding: EdgeInsets.only(
                                        bottom: 20, left: 10, right: 10),
                                    onConfirm: () async {
                                      await groupController.removeMember(
                                          groupId: chat.value!.id!,
                                          memberId: chat
                                              .value!.members![index].userId!);
                                      chatController.fetchChatType(chat.value!.id!);
                                    },
                                  );
                                }
                              : null,
                          leading: CircleAvatar(
                            // radius: 25,
                            backgroundImage: NetworkImage(
                                chat.value!.members![index].profileImageUrl! ??
                                    ''),
                          ),
                          title: Text(
                              "${chat.value!.members![index].firstName} ${chat.value!.members![index].lastName}"),
                          subtitle: Text(
                            chat.value!.members![index].role!,
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          thickness: 0.5,
                          indent: 15,
                          endIndent: 15,
                        );
                      }),
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
}
