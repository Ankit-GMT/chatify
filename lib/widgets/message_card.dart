import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageCard extends StatelessWidget {
  final String text;
  final bool isMe;

  const MessageCard({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            margin: EdgeInsets.symmetric(vertical: Get.height * .01),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Text(
                          "05:12 PM",
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.white.withAlpha(200),
                          ),
                        ),
                       isMe ? Icon(Icons.done_all,size: 12,color: Colors.blue):SizedBox() ,
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
