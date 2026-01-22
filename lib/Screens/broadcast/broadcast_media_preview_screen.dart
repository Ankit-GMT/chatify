import 'dart:io';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import 'broadcast_media_contacts_screen.dart';

class BroadcastMediaPreviewScreen extends StatefulWidget {
  const BroadcastMediaPreviewScreen({super.key});

  @override
  State<BroadcastMediaPreviewScreen> createState() =>
      _BroadcastMediaPreviewScreenState();
}

class _BroadcastMediaPreviewScreenState
    extends State<BroadcastMediaPreviewScreen> {
  final captionController = TextEditingController();
  VideoPlayerController? _videoController;

  late File file;
  late String type;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    file = args["file"];
    type = args["type"];

    if (type == "VIDEO") {
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Get.to(
                () => MediaBroadcastContactsScreen(),
                arguments: {
                  "file": file,
                  "type": type,
                  "caption": captionController.text.trim(),
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          (type == "IMAGE") || (type == "VIDEO")
              ? Expanded(
                  child: _buildPreview(),
                )
              : Center(
                  child: _buildPreview(),
                ),

          /// Caption
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: "Add a caption...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- PREVIEW BUILDER ----------------

  Widget _buildPreview() {
    if (type == "IMAGE") {
      return Image.file(file);
    }

    if (type == "VIDEO") {
      return _buildVideoPreview();
    }

    return _buildDocumentPreview();
  }

  /// ---------------- VIDEO PREVIEW ----------------

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            /// Video area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),

                  /// Play / Pause overlay
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 64,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            /// Seek bar (fixed height)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
              ),
            ),
          ],
        );
      },
    );
  }

  /// ---------------- DOCUMENT PREVIEW ----------------

  Widget _buildDocumentPreview() {
    final fileName = p.basename(file.path);
    final fileSize = _formatBytes(file.lengthSync());

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 80,color: Colors.grey,),
          const SizedBox(height: 12),
          Text(
            fileName,
            textAlign: TextAlign.center,
            style:  TextStyle(fontWeight: FontWeight.w600,color: AppColors.black),
          ),
          const SizedBox(height: 4),
          Text(
            fileSize,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// ---------------- FILE SIZE FORMAT ----------------

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (bytes.toString().length - 1) ~/ 3;
    return "${(bytes / (1 << (10 * i))).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
