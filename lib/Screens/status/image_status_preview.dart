import 'dart:io';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chatify/controllers/status_controller.dart';

class ImageStatusPreviewScreen extends StatefulWidget {
  final File file;
  final StatusController? controller;
  final DateTime? scheduledAt;
  final bool isScheduledPreview;


  const ImageStatusPreviewScreen({
    super.key,
    required this.file,
    required this.controller,
    this.scheduledAt,
    this.isScheduledPreview = false,
  });

  @override
  State<ImageStatusPreviewScreen> createState() =>
      _ImageStatusPreviewScreenState();
}

class _ImageStatusPreviewScreenState
    extends State<ImageStatusPreviewScreen> {
  bool uploading = false;
  final TextEditingController _captionController = TextEditingController();

  Future<void> upload() async {
    setState(() => uploading = true);

    final bool success ;
    final caption = _captionController.text.trim();

    if (widget.scheduledAt != null) {
    success = await widget.controller!.uploadScheduledMediaStatus(
        file: widget.file,
        type: "IMAGE", // or VIDEO
        caption: caption.isEmpty ? null : caption,
        scheduledAt: widget.scheduledAt!,
      );
    } else {
    success = await widget.controller!.uploadMediaStatus(
        file: widget.file,
        type: "IMAGE",
        caption: caption.isEmpty ? null : caption,
      );
    }
    if (success) {
      widget.controller!.loadStatuses();
      widget.controller!.loadScheduledStatuses();
      Get.back(result: true);

    } else {
      Get.back();
      Get.snackbar("Error", "Failed to upload status",backgroundColor: Colors.red,colorText: AppColors.white);
    }

  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: widget.isScheduledPreview
                ? Image.network(networkImg)
                : Image.file(widget.file, fit: BoxFit.contain),
          ),

          // Caption input
          Positioned(
            left: 16,
            right: 16,
            bottom: 50,
            child: TextField(
              controller: _captionController,
              maxLines: 3,
              cursorColor: AppColors.white,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add a caption...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: widget.isScheduledPreview ? SizedBox.shrink() : FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: uploading ? null : upload,
        child: uploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.send),
      ),
    );
  }
}
