import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Dialogs {
  static void editProfile(
    BuildContext context,
    TextEditingController controller,
    String title,
    VoidCallback? onSave)
  {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
            title: Text("Edit $title"),
            content: TextField(
              controller: controller,
              maxLines: 2,
              minLines: 1,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white
                ),
                onPressed: onSave,
                child: Text("Update"),
              ),
            ]);
      },
    );
  }
}
