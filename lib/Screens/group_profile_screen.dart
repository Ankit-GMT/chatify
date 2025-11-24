import 'package:chatify/Screens/add_group_members_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/group_controller.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/widgets/custom_box.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class GroupProfileScreen extends StatelessWidget {
  final ChatType? chatType;

  const GroupProfileScreen({super.key, required this.chatType});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final messageController = Get.find<MessageController>();
    final groupController = Get.put(GroupController());
    final tabController = Get.find<TabBarController>();

    final myId = profileController.user.value?.id;

    final isAdmin = chatType?.members
        ?.any((m) => m.id == myId && m.role == "ADMIN") ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            spacing: 20,
            children: [
              SizedBox(height: Get.height * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
                ],
              ),
              GestureDetector(
                onTap: () {
                  groupController.editImage(ImageSource.gallery, chatType!.id!);
                },
                  child: ProfileAvatar(imageUrl: chatType!.groupImageUrl!, radius: 50)),
              Column(
                children: [
                  Text(
                    chatType!.name! ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${chatType!.members!.length.toString()} Members",
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
                      final channelId = chatType!.id.toString();
                      print('StartCAll channel:-   $channelId');
                      final rIds = chatType?.members
                          ?.map((m) => m.userId)
                          .where((id) => id != myId)
                          .toList();
                      final receiverIds =
                          rIds?.map((id) => id.toString()).toList() ?? [];
                      print("Start call receiverids:- $receiverIds");
                      messageController.startGroupCall(
                          context: context,
                          channelId: channelId,
                          callerId: profileController.user.value!.id.toString(),
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
                      final channelId = chatType!.id.toString();
                      print('StartCAll channel:-   $channelId');
                      final rIds = chatType?.members
                          ?.map((m) => m.userId)
                          .where((id) => id != myId)
                          .toList();
                      final receiverIds =
                          rIds?.map((id) => id.toString()).toList() ?? [];
                      print("Start call receiverids:- $receiverIds");
                      messageController.startGroupCall(
                          context: context,
                          channelId: channelId,
                          callerId: profileController.user.value!.id.toString(),
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
                            groupId: chatType!.id!,
                          ));
                      groupController.loadCurrentMembers(
                          chatType!.members!.map((e) => e.userId!).toList());
                    },
                  ),
                ],
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Media",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                    "Members",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "View All",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey),
                  ),
                ],
              ),
              SizedBox(
                height: 250,
                child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: chatType!.members!.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          // radius: 25,
                          backgroundImage: NetworkImage(
                              chatType!.members![index].profileImageUrl! ?? ''),
                        ),
                        title: Text(
                            "${chatType!.members![index].firstName} ${chatType!.members![index].lastName}"),
                        subtitle: Text(
                          chatType!.members![index].role!,
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
               isAdmin ? SizedBox():
               CustomTile(
                title: "Exit Group",
                image: "assets/images/profile_exit.png",
                onTap: () async {
                  await groupController.exitGroup(groupId: chatType!.id!);
                  await tabController.getAllChats();
                },
              ),
              // CustomTile(
              //   title: "Report Group",
              //   image: "assets/images/profile_report.png",
              //   onTap: () {},
              // ),
              isAdmin ?
              ListTile(
                onTap: () async {
                  await groupController.deleteGroup(groupId: chatType!.id!);
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
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary, size: 15),
              ): SizedBox(),
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
    );
  }
}
