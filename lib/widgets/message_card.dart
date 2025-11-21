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
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class MessageCard extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Function()? onDownload;

  const MessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.onDownload,
  });

  void openDocument(String url) async {
    String filePath = await downloadFile(url);
    OpenFilex.open(filePath);
  }

  Future<String> downloadFile(String url) async {
    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/${url.split('/').last}";

    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [

        isMe
            ? SizedBox()
            : Row(
          children: [
            ProfileAvatar(imageUrl: message.senderProfileImageUrl, radius: 10),
            SizedBox(width: 5),
            Text("${message.senderFirstName} ${message.senderLastName}", style: TextStyle(fontSize: 10)),
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

                    if (message.type == "IMAGE")
                      // GestureDetector(
                      //     onTap: () {
                      //       Get.to(() => FullImageViewer(imageUrl: message.fileUrl ?? ''));
                      //     },
                      //     child: buildImageMessage()),
                      buildImageMessage(),

                    if (message.type == "AUDIO")
                      GestureDetector(
                          onTap: () {
                            openAudioPlayerSheet(context, message.fileUrl ?? '');
                          },
                          child: buildAudioMessage()
                      ),

                    if (message.type == "VIDEO")
                      // GestureDetector(
                      //     onTap: () {
                      //       Get.to(() => VideoPlayerScreen(videoUrl: message.fileUrl ?? ''));
                      //     },
                      //     child: buildVideoMessage()),
                      buildVideoMessage(),

                    if (message.type == "DOCUMENT")
                      GestureDetector(
                          onTap: () {
                            openDocument(message.fileUrl ?? '');
                          },
                          child: buildDocumentMessage()),

                    if (message.type == "TEXT")
                      buildTextMessage(),

                    SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TimeFormat.getFormattedTime(
                              context: context, time: message.sentAt.toString()),
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.white.withAlpha(200),
                          ),
                        ),
                        SizedBox(width: 4),
                        isMe
                            ? Icon(Icons.done_all,
                            size: 12, color: Colors.blue)
                            : SizedBox()
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

  // For image
  // Widget buildImageMessage() {
  //   return Column(
  //     spacing: 6,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(10),
  //         child: Image.network(
  //           // imageUrl,
  //           "https://picsum.photos/200/300",
  //           width: 200,
  //           height: 200,
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //       if (message.content.isNotEmpty)
  //         Text(message.content, style: TextStyle(color: AppColors.white)),
  //     ],
  //   );
  // }

  Widget buildImageMessage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.thumbnailUrl ?? message.fileUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),

        if (!message.isDownloaded)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Center(
                child: message.downloadProgress == 0
                    ? IconButton(
                  icon: Icon(Icons.download, color: Colors.white, size: 32),
                  onPressed: () {
                    print("Download tapped");
                    onDownload?.call();
                  },
                )
                    : SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    value: message.downloadProgress,
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

        if (message.isDownloaded)
          Positioned.fill(
            child: InkWell(
              onTap: () => Get.to(() => FullImageViewer(imageUrl: message.localPath!)),
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  // for Audio files
  Widget buildAudioMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(55),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ),
          SizedBox(width: 8),
          Container(width: 80, height: 2, color: Colors.white),
          SizedBox(width: 8),
          Text("0:12",
              style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 10)),
        ],
      ),
    );
  }

  // for Video message

  // Widget buildVideoMessage() {
  //   return Stack(
  //     alignment: Alignment.center,
  //     children: [
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(10),
  //         child: Image.network(
  //           // show thumbnail
  //           // imageUrl,
  //           "https://picsum.photos/300/300",
  //           width: 200,
  //           height: 200,
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //       Container(
  //         decoration: BoxDecoration(
  //           color: Colors.black45,
  //           shape: BoxShape.circle,
  //         ),
  //         padding: EdgeInsets.all(10),
  //         child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
  //       ),
  //     ],
  //   );
  // }
  Widget buildVideoMessage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: message.thumbnailUrl != null
              ? Image.network(
            message.thumbnailUrl!,
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
        if (message.downloadProgress > 0 && message.downloadProgress < 1)
          CircularProgressIndicator(
            value: message.downloadProgress,
            strokeWidth: 3,
            color: AppColors.primary,
          ),

        // if downloaded => play button
        if (message.localPath != null)
          GestureDetector(
            onTap: () {
              Get.to(() => VideoPlayerScreen(videoUrl: message.localPath!));
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
        if (message.localPath == null &&
            (message.downloadProgress == 0))
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
    );
  }


// for document message

  Widget buildDocumentMessage() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message.content.isNotEmpty ? message.content : "Document",
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
