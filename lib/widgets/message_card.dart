import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/time_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageCard extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const MessageCard({super.key, required this.text, required this.isMe, required this.time});

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
              color: isMe ? AppColors.primary : Get.isDarkMode ? AppColors.white.withAlpha(50): AppColors.black,
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
                          TimeFormat.getFormattedTime(context: context, time: time),
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
