import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/widgets/chat_user_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllChats extends StatelessWidget {
  const AllChats({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        return ChatUserCard(
          index: index,
          onTap: (){
            Get.to(()=> ChatScreen());
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          thickness: 1,
          indent: 15,
          endIndent: 15,
        );
      },
      itemCount: 20,
    );
  }
}
