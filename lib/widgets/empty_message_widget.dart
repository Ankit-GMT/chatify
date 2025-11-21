import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';

class EmptyMessagesWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool isGroup;

  const EmptyMessagesWidget(
      {super.key, required this.onTap, this.isGroup = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isGroup
                ? "Create a new group with your friends!"
                : "Start a new conversation with your friends!",

          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onTap,
            child: Text(isGroup ? "Create Group" : "Start Chat"),
          ),
        ],
      ),
    );
  }
}
