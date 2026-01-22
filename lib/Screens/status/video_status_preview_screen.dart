import 'dart:io';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chatify/controllers/status_controller.dart';

class VideoStatusPreviewScreen extends StatefulWidget {
  final File file;
  final StatusController? controller;
  final DateTime? scheduledAt;
  final bool isScheduledPreview;

  const VideoStatusPreviewScreen({
    super.key,
    required this.file,
    required this.controller,
    this.scheduledAt,
    this.isScheduledPreview = false,
  });

  @override
  State<VideoStatusPreviewScreen> createState() =>
      _VideoStatusPreviewScreenState();
}

class _VideoStatusPreviewScreenState
    extends State<VideoStatusPreviewScreen> {

  late VideoPlayerController _player;
  bool uploading = false;
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        _player.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _player.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> upload() async {
    setState(() => uploading = true);

    final bool success ;
    final caption = _captionController.text.trim();

    if (widget.scheduledAt != null) {
    success = await widget.controller!.uploadScheduledMediaStatus(
        file: widget.file,
        type: "VIDEO", // or VIDEO
        caption: caption.isEmpty ? null : caption,
        scheduledAt: widget.scheduledAt!,
      );
    } else {
    success = await widget.controller!.uploadMediaStatus(
        file: widget.file,
        type: "VIDEO",
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
            child:
            _player.value.isInitialized
                ? AspectRatio(
              aspectRatio: _player.value.aspectRatio,
              child: VideoPlayer(_player),
            )
                : const CircularProgressIndicator(),
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
      floatingActionButton:widget.isScheduledPreview ? SizedBox.shrink() : FloatingActionButton(
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
