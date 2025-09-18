import 'package:chatify/Screens/profile_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/widgets/message_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.chatBackground,
      appBar: AppBar(
        toolbarHeight: 85,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          height: 85,
          padding: EdgeInsets.only(left: Get.width * 0.13,right: Get.width*0.04),
          decoration: BoxDecoration(
              color: Color(0xff2A2A2A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Get.to(()=> ProfileScreen());
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d"),
                    ),
                  ),
                  SizedBox(
                    width: Get.width * 0.04,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: Get.width*0.25,
                        child: Text(
                          "Ankit Patel",
                          maxLines: 1,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.white),
                        ),
                      ),
                      Text(
                        "Online",
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          color: AppColors.white.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Image.asset("assets/images/chat_call.png", scale: 2),
                  ),
                  SizedBox(
                    width: Get.width * 0.05,
                  ),
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      "assets/images/chat_videocall.png",
                      scale: 2,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05,vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                reverse: true,
                padding: EdgeInsets.only(top: Get.height * .01),
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
              return MessageCard(text: messages[index].text,isMe: messages[index].isMe,);
            },),),
            Container(
              width: double.infinity,
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primary,
                        prefixIcon: IconButton(onPressed: (){}, icon: Icon(Icons.emoji_emotions_outlined,color: AppColors.white.withAlpha(200),),),
                        hintText: "Type a message . . .",
                        hintStyle: TextStyle(color: AppColors.white.withAlpha(155)),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(20),
                        )
                      ),
                    ),
                  ),
                  SizedBox(width: Get.width*0.02,),
                  Container(
                    height: 44,
                    width: Get.width*0.18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset("assets/images/chat_add.png",scale: 2,),
                        Image.asset("assets/images/chat_mic.png",scale: 2,),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
