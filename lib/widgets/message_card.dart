import 'dart:io';

import 'package:chatify/Screens/Media%20Viewer%20Screens/audio_player_screen.dart';
import 'package:chatify/Screens/Media%20Viewer%20Screens/full_image_viewer.dart';
import 'package:chatify/Screens/Media%20Viewer%20Screens/video_player_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/time_format.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

class MessageCard extends StatelessWidget {
  final Message message;
  final Message? previousMessage;
  final bool isMe;
  final Function()? onDownload;

  const MessageCard({
    super.key,
    required this.message,
    required this.previousMessage,
    required this.isMe,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == "SYSTEM_BACKGROUND_CHANGE") {
      return _buildSystemMessage();
    }

    final showDateSeparator = _shouldShowDateSeparator();

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showDateSeparator && message.dateLabel != null && message.dateLabel!.isNotEmpty)
          _buildTimelineMessage(),
        isMe
            ? SizedBox()
            : Row(
                children: [
                  ProfileAvatar(
                      imageUrl: message.senderProfileImageUrl ?? '',
                      radius: 10),
                  SizedBox(width: 5),
                  Text("${message.senderFirstName} ${message.senderLastName}",
                      style: TextStyle(fontSize: 10)),
                ],
              ),
        Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                margin: EdgeInsets.symmetric(vertical: Get.height * .01),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primary
                      : Get.isDarkMode
                          ? AppColors.white.withAlpha(50)
                          : AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                ),

                // Message Or image
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == "IMAGE") buildImageMessage(),
                    if (message.type == "AUDIO") buildAudioMessage(),
                    if (message.type == "VIDEO") buildVideoMessage(),
                    if (message.type == "DOCUMENT") buildDocumentMessage(),
                    if (message.type == "TEXT") buildTextMessage(),
                    SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TimeFormat.getFormattedTime(
                              context: context,
                              time: message.sentAt.toString()),
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.white.withAlpha(200),
                          ),
                        ),
                        SizedBox(width: 4),
                        isMe
                            ? Obx(() => Icon(
                                  Icons.done_all,
                                  size: 12,
                                  color: message.isRead.value
                                      ? Colors.blue
                                      : Colors.grey,
                                ))
                            : const SizedBox()
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _shouldShowDateSeparator() {
    // First message in whole list (oldest)
    if (previousMessage == null) return true;

    // If day is different from the OLDER message
    return message.dateLabel != previousMessage!.dateLabel;
  }

  // for other messages
  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(125),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  //for time,day
  Widget _buildTimelineMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.dateLabel ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  // For image
  Widget buildImageMessage() {
    return Obx(() => Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isMe
              ? Image.file(
            File(message.localPath.value ?? ""),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          )
              : Image.network(
            message.thumbnailUrl ?? message.fileUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        if (message.localPath.value != null && !isMe)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: message.downloadProgress.value == 0
                    ? IconButton(
                  icon:
                  Icon(Icons.download, color: Colors.white, size: 32),
                  onPressed: () {
                    debugPrint("Download tapped");
                    onDownload?.call();
                  },
                )
                    : SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    value: message.downloadProgress.value,
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        if (message.localPath.value != null || isMe)
          Positioned.fill(
            child: InkWell(
              onTap: () => Get.to(
                      () => FullImageViewer(imageUrl: message.localPath.value!)),
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    ),);
  }

  Widget buildAudioMessage() {
    return Obx(
      () => Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                (message.localPath.value != null && !isMe)
                    ? message.downloadProgress.value == 0
                        ? GestureDetector(
                            onTap: onDownload,
                            child: Icon(Icons.download,
                                color: Colors.white, size: 22),
                          )
                        : CircularProgressIndicator(
                            value: message.downloadProgress.value,
                            strokeWidth: 3,
                            color: AppColors.primary,
                          )
                    : Icon(Icons.audiotrack, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  message.fileName ?? "Audio File",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          // if (!message.localPath.value != null)
          //   Positioned.fill(
          //     child: Center(
          //       child: message.downloadProgress.value == 0
          //           ? IconButton(
          //               icon: Icon(Icons.download, color: Colors.white, size: 28),
          //               onPressed: onDownload)
          //           : CircularProgressIndicator(
          //               value: message.downloadProgress.value,
          //               strokeWidth: 3,
          //               color: AppColors.primary,
          //             ),
          //     ),
          //   ),
          if (message.localPath.value != null || isMe)
            Positioned.fill(
              child: InkWell(
                onTap: () {
                  openAudioPlayerSheet(
                      Get.context!,
                      message.localPath.value ?? message.fileUrl!,
                      message.fileName!);
                },
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }

  // for Video message
  Widget buildVideoMessage() {
    return Obx(() => Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: message.thumbnailUrl != null ||
                      message.localPath.value != null
                  ? Image.network(
                      isMe ? message.localPath.value! : message.thumbnailUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      color: Colors.black26,
                    ),
            ),

            // if downloading show progress
            if (message.downloadProgress.value > 0 && message.downloadProgress.value < 1)
              CircularProgressIndicator(
                value: message.downloadProgress.value,
                strokeWidth: 3,
                color: AppColors.primary,
              ),

            // if downloaded => play button
            if (message.localPath.value != null || isMe)
              GestureDetector(
                onTap: () {
                  Get.to(() =>
                      VideoPlayerScreen(videoUrl: message.localPath.value!));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),

            // if NOT downloaded => download icon
            if (message.localPath.value == null &&
                (message.downloadProgress.value == 0) &&
                !isMe)
              GestureDetector(
                onTap: onDownload,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.download, color: Colors.white, size: 28),
                ),
              ),
          ],
        ));
  }

  Widget buildDocumentMessage() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                (message.localPath.value != null && !isMe)
                    ? message.downloadProgress.value == 0
                        ? GestureDetector(
                            onTap: onDownload,
                            child: Icon(Icons.download,
                                color: Colors.white, size: 22))
                        : CircularProgressIndicator(
                            value: message.downloadProgress.value,
                            strokeWidth: 3,
                          )
                    : Icon(Icons.insert_drive_file,
                        color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  message.fileName ?? "Document",
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // if (!message.localPath.value != null)
        //   Positioned.fill(
        //     child: Center(
        //       child: message.downloadProgress.value == 0
        //           ? IconButton(
        //               icon: Icon(Icons.download, color: Colors.white, size: 28),
        //               onPressed: onDownload,
        //             )
        //           : CircularProgressIndicator(
        //               value: message.downloadProgress.value,
        //               strokeWidth: 3,
        //             ),
        //     ),
        //   ),
        if (message.localPath.value != null || isMe)
          Positioned.fill(
            child: InkWell(
              onTap: () async {
                await OpenFilex.open(message.localPath.value!);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  // for text message

  Widget buildTextMessage() {
    return Text(
      message.content,
      style: TextStyle(color: AppColors.white),
    );
  }
}
