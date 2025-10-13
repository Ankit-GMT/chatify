import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupChats extends StatelessWidget {
  final userController = Get.put(UserController());

  GroupChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => ListView.separated(
            physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return ChatUserCard(
            index: index,
            onTap: () {
              Get.to(() => ChatScreen(
                chatUser: null,
                chatType: userController.groupChats.elementAt(index),
              ));
            },
            chatUser: null,
            chatType: userController.groupChats.elementAt(index),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            thickness: 1,
            indent: 15,
            endIndent: 15,
          );
        },
        itemCount: userController.groupChats.length,
      ),
    );
  }
}