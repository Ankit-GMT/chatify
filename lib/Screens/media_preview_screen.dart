// import 'dart:io';
//
// import 'package:chatify/constants/app_colors.dart';
// import 'package:chatify/controllers/chat_screen_controller.dart';
// import 'package:chatify/controllers/image_preview_controller.dart';
// import 'package:chatify/controllers/message_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class MediaPreviewScreen extends StatelessWidget {
//   final String filePath;
//   final int chatId;
//   final String type;
//
//   MediaPreviewScreen({
//     super.key,
//     required this.filePath,
//     required this.chatId,
//     required this.type,
//   });
//
//   final controller = Get.put(ImagePreviewController());
//   final messageController = Get.put(MessageController());
//   late final chatController = Get.put(ChatScreenController(chatId: chatId));
//
//   @override
//   Widget build(BuildContext context) {
//     controller.setImage(filePath);
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // MEDIA VIEW
//           Positioned.fill(
//             child: Center(
//               child: buildPreview(),
//             ),
//           ),
//           // TOP BAR
//           Positioned(
//             top: 40,
//             left: 10,
//             right: 10,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.black54,
//                   child: IconButton(
//                     icon: Icon(Icons.close, color: Colors.white),
//                     onPressed: () => Get.back(),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 40,
//                 ),
//               ],
//             ),
//           ),
//
//           // CAPTION + SEND
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: EdgeInsets.all(10),
//               color: Colors.black54,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       onChanged: (v) => controller.caption.value = v,
//                       style: TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                         hintText: "Add a caption...",
//                         hintStyle: TextStyle(color: Colors.white70),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   Obx(
//                     () => messageController.isSending.value
//                         ? CircularProgressIndicator(
//                             color: AppColors.white,
//                           )
//                         : CircleAvatar(
//                             radius: 25,
//                             backgroundColor: AppColors.primary,
//                             child: IconButton(
//                               icon: Icon(Icons.send, color: Colors.white),
//                               onPressed: () async {
//                                 await messageController.sendMedia(
//                                   chatId.toString(),
//                                   File(filePath),
//                                   type: type,
//                                   caption: controller.caption.value,
//                                 );
//                                 await chatController.loadMessages(chatId);
//
//                                 if (context.mounted) Navigator.pop(context);
//                               },
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget buildPreview() {
//     if (type == "VIDEO") {
//       return Icon(Icons.videocam, color: Colors.white, size: 80);
//     }
//     if (type == "AUDIO") {
//       return Icon(Icons.audiotrack, color: Colors.white, size: 80);
//     }
//     if (type == "DOCUMENT") {
//       return Icon(Icons.insert_drive_file, color: Colors.white, size: 80);
//     }
//
//     // fallback
//     return Icon(Icons.file_copy, color: Colors.white, size: 80);
//   }
// }

import 'dart:io';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/media_preview_controller.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

class MediaPreviewScreen extends StatelessWidget {
  final String filePath;
  final int chatId;
  final String type;

  MediaPreviewScreen({
    super.key,
    required this.filePath,
    required this.chatId,
    required this.type,
  });

  final messageController = Get.put(MessageController());

  @override
  Widget build(BuildContext context) {
    // Media controller
    final mediaCtrl = Get.put(MediaPreviewController(filePath, type));


    if (type == "IMAGE") {
      mediaCtrl.setImage(filePath);
    }

    // Chat controller
    final chatController = Get.put(ChatScreenController(chatId: chatId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(child: _buildPreview(mediaCtrl)),
          ),

          // TOP BAR
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),

                if (type == "IMAGE")
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(Icons.crop, color: Colors.white),
                      onPressed: mediaCtrl.cropImage,
                    ),
                  )
                else
                  SizedBox(width: 40),
              ],
            ),
          ),

          // CAPTION + SEND BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.black54,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => mediaCtrl.caption.value = v,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a caption...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  Obx(
                        () => messageController.isSending.value
                        ? CircularProgressIndicator(color: Colors.white)
                        : CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: () async {
                          final sendingFile = type == "IMAGE"
                              ? mediaCtrl.imageFile.value
                              : File(filePath);

                          await messageController.sendMedia(
                            chatId.toString(),
                            sendingFile,
                            type: type,
                            caption: mediaCtrl.caption.value,
                          );

                          await chatController.loadMessages(chatId);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // UI FOR EACH MEDIA TYPE
  Widget _buildPreview(
      MediaPreviewController mediaCtrl) {
    switch (type) {
      case "IMAGE":
        return Obx(() => Image.file(
          mediaCtrl.imageFile.value,
          fit: BoxFit.contain,
        ));

      case "VIDEO":
        return Obx(() {
          if (!mediaCtrl.videoInitialized.value) {
            return CircularProgressIndicator(color: Colors.white);
          }

          return GestureDetector(
            onTap: () {
              mediaCtrl.videoController!.value.isPlaying
                  ? mediaCtrl.videoController!.pause()
                  : mediaCtrl.videoController!.play();
            },
            child: AspectRatio(
              aspectRatio: mediaCtrl.videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(mediaCtrl.videoController!),
                  Icon(
                    mediaCtrl.videoController!.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: Colors.white,
                    size: 70,
                  ),
                ],
              ),
            ),
          );
        });

      case "AUDIO":
        return Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.audiotrack, color: Colors.white, size: 85),
              SizedBox(height: 10),
              Text(
                File(mediaCtrl.filePath).path.split('/').last,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              IconButton(
                icon: Icon(
                  mediaCtrl.isPlayingAudio.value
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 60,
                ),
                onPressed: mediaCtrl.toggleAudio,
              ),
            ],
          );
        });

      case "DOCUMENT":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.white, size: 90),
            SizedBox(height: 10),
            Text(
              File(mediaCtrl.filePath).path.split('/').last,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        );

      default:
        return Icon(Icons.file_copy, color: Colors.white, size: 80);
    }
  }
}
