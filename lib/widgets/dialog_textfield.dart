import 'package:flutter/material.dart';

class Dialogs {
   static void editProfile(
    BuildContext context,
    TextEditingController controller,
    String title,
      VoidCallback? onSave,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
            title: Text("Edit $title"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: onSave,
                child: Text("Save"),
              ),
            ]);
      },
    );
  }
}
