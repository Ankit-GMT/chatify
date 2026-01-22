import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:chatify/controllers/status_controller.dart';

class ImageStatusEditorScreen extends StatelessWidget {
  final File file;
  final StatusController controller;

  const ImageStatusEditorScreen({
    super.key,
    required this.file,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ImageEditor(
        image: file.readAsBytesSync(),
        // onDone: (editedImage) async {
        //   final editedFile = File(
        //     '${file.parent.path}/edited_status.jpg',
        //   )..writeAsBytesSync(editedImage);
        //
        //   Get.back();
        //   await Get.to(() => ImageStatusPreviewScreen(
        //     file: editedFile,
        //     controller: controller,
        //   ));
        // },
      ),
    );
  }
}
