import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllChats extends StatelessWidget {
  final userController = Get.put(UserController());
  final profileController = Get.put(ProfileController());

  AllChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () =>
          ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final chat = userController.allChats[index];
          final isSelected = userController.selectedChats.contains(chat);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => userController.toggleSelection(chat),
            child: ChatUserCard(
              index: index,
              onTap: () {
                if (userController.isSelectionMode.value) {
                  userController.toggleSelection(chat);
                } else {
                  Get.to(() => ChatScreen(
                    chatUser: null,
                    chatType: userController.allChats.elementAt(index),
                  ));
                }

              },
              chatUser: null,
              chatType: userController.allChats.elementAt(index),
              isSelected: isSelected,
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            thickness: 1,
            indent: 15,
            endIndent: 15,
          );
        },
        itemCount: userController.allChats.length,
      ),
    );
  }
}
