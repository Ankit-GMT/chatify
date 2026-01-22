import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chatify/constants/app_colors.dart';
import '../models/chat_background.dart';
import '../controllers/chat_background_controller.dart';

class ChatBackgroundPreview extends StatelessWidget {
  final ChatBackground? background;
  final String? imageUrl; // default
  final File? galleryFile; //for gallery

  const ChatBackgroundPreview({
    super.key,
    this.background,
    this.imageUrl,
    this.galleryFile,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatBackgroundController>();

    final String bgUrl = background?.imageUrl ?? imageUrl ?? "";

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text("Preview"),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: Stack(
        children: [
          // 🔹 Background preview
          Positioned.fill(bottom: 60, child: _buildBackground()),

          // 🔹 Dark overlay (readability)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),

          // 🔹 Fake chat preview
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _bubble(
                    "Hello 👋",
                    false,
                  ),
                  _bubble(
                    "Hii, how are you?",
                    true,
                  ),
                  _bubble(
                    "Tell me",
                    false,
                  ),
                  _bubble(
                    "This is how your chat will look",
                    true,
                  ),
                  _bubble(
                    "Nice 👍",
                    false,
                  ),
                  _bubble(
                    "Bye...",
                    true,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // 🔹 Bottom buttons
          Positioned(
            bottom: 10,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black.withAlpha(5),
                        foregroundColor: AppColors.white,
                        side: BorderSide(color: AppColors.white)),
                    onPressed: () =>
                        controller.isLoading.value ? null : Get.back(),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white),
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                      if (imageUrl != null &&
                          imageUrl!.startsWith("assets/")) {
                        controller.resetToDefaultBackground();
                        return;
                      }

                      // PREDEFINED API BACKGROUND
                      if (background != null) {
                        controller.applyBackground(background!);
                        return;
                      }

                      //  GALLERY UPLOAD
                      if (galleryFile != null) {
                        controller.uploadGalleryBackground(galleryFile!);
                      }
                    },
                    child: controller.isLoading.value
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text("Apply"),
                  ),
                ),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Get.isDarkMode
                  ? AppColors.white.withAlpha(50)
                  : AppColors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (galleryFile != null) {
      return Image.file(galleryFile!, fit: BoxFit.cover);
    }

    if (imageUrl != null) {
      return imageUrl!.startsWith("http")
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : Image.asset(imageUrl!, fit: BoxFit.cover);
    }

    return Image.network(background!.imageUrl, fit: BoxFit.cover);
  }
}
