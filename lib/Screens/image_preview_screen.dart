import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/media_preview_controller.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
//
// class ImagePreviewScreen extends StatelessWidget {
//   final String imagePath;
//   final int chatId;
//
//   ImagePreviewScreen(
//       {super.key, required this.imagePath, required this.chatId});
//
//   final ImagePreviewController controller = Get.put(ImagePreviewController());
//
//   final messageController = Get.put(MessageController());
//   late final chatController = Get.put(ChatScreenController(chatId: chatId));
//
//   @override
//   Widget build(BuildContext context) {
//     controller.setImage(imagePath);
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // IMAGE VIEW
//           Obx(() {
//             return Positioned.fill(
//               child: Image.file(
//                 controller.imageFile.value,
//                 fit: BoxFit.contain,
//               ),
//             );
//           }),
//
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
//                 CircleAvatar(
//                   backgroundColor: Colors.black54,
//                   child: IconButton(
//                     icon: Icon(Icons.crop, color: Colors.white),
//                     onPressed: controller.cropImage,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // BOTTOM
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.all(10),
//               color: Colors.black54,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.white10,
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       child: TextField(
//                         onChanged: (val) => controller.caption.value = val,
//                         style: TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintText: "Add a caption...",
//                           hintStyle: TextStyle(color: Colors.white70),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
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
//                                     chatId.toString(),
//                                     controller.imageFile.value,
//                                     caption: controller.caption.value,
//                                     type: "IMAGE");
//                                 await chatController.loadMessages(chatId);
//                                 if (context.mounted) {
//                                   Navigator.pop(context);
//                                 }
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
// }

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  final int chatId;

  ImagePreviewScreen({
    super.key,
    required this.imagePath,
    required this.chatId,
  }) {
    // Put controllers here, NOT in build()
    Get.put(MediaPreviewController(imagePath, "IMAGE"));
    Get.put(MessageController());
    Get.put(ChatScreenController(chatId: chatId));

    // load image one time
    final c = Get.find<MediaPreviewController>();
    c.setImage(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MediaPreviewController>();
    final messageController = Get.find<MessageController>();
    final chatController = Get.find<ChatScreenController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // IMAGE PREVIEW
          Obx(() {
            return Positioned.fill(
              child: Image.file(
                controller.imageFile.value,
                fit: BoxFit.contain,
              ),
            );
          }),

          // TOP BAR
          Positioned(
            top: 40,
            left: 20,
            right: 20,
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
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(Icons.crop, color: Colors.white),
                    onPressed: controller.cropImage,
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        onChanged: (val) => controller.caption.value = val,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Add a caption...",
                          hintStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Obx(
                        () => messageController.isSending.value
                        ? CircularProgressIndicator(color: Colors.white)
                        : GestureDetector(
                      onTap: () async {
                        await messageController.sendMedia(
                          chatId.toString(),
                          controller.imageFile.value,
                          caption: controller.caption.value,
                          type: "IMAGE",
                        );

                        await chatController.loadMessages(chatId);

                        if (context.mounted) Get.back();
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
