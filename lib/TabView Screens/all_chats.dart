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
        itemBuilder: (context, index) {
          return ChatUserCard(
            index: index,
            onTap: () {
              Get.to(() => ChatScreen(
                    chatUser: null,
                chatType: userController.allChats.elementAt(index),
                  ));
            },
            chatUser: null,
            chatType: userController.allChats.elementAt(index),
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
