import 'package:chatify/Screens/group_profile_screen.dart';
import 'package:chatify/Screens/profile_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/widgets/dialog_textfield.dart';
import 'package:chatify/widgets/message_card.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

final GlobalKey attachKey = GlobalKey();

class ChatScreen extends StatelessWidget {
  int? chatId;

  ChatScreen({super.key, this.chatId});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.put(ChatScreenController(chatId: chatId!));
    final messageController = Get.put(MessageController());

    TextEditingController msgController = TextEditingController();


    void showAttachmentMenu(BuildContext context, GlobalKey key) {
      final RenderBox renderBox =
          key.currentContext!.findRenderObject() as RenderBox;
      final Offset offset = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;

      showMenu(
        color: AppColors.primary.withAlpha(200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        context: context,

        // Position the popup ABOVE the button
        position: RelativeRect.fromLTRB(offset.dx, offset.dy + size.height + 30,
            offset.dx + size.width + 50, offset.dy),

        items: [
          _popupItem(Icons.camera_alt_outlined, "Camera", () async {
            await messageController.pickImage(ImageSource.camera, chatId!);
            debugPrint("Pick camera Image");
            // open image picker
          }),
          _popupItem(Icons.image, "Image", () async {
            await messageController.pickImage(ImageSource.gallery, chatId!);
            debugPrint("Pick Image");
            // open image picker
          }),
          _popupItem(Icons.video_collection, "Video", () async {
            await messageController.pickVideo(chatId!);
            debugPrint("Pick Video");
          }),
          _popupItem(Icons.mic, "Audio", () async {
            await messageController.pickAudio(chatId!);
            debugPrint("Pick Audio");
          }),
          _popupItem(Icons.file_copy, "Document", () async {
            await messageController.pickDocument(chatId!);
            debugPrint("Pick Document");
          }),
        ],
      );
    }

    Future<void> sendMessage() async {
      if (msgController.text.trim().isEmpty) return;

      final box = GetStorage();
      final myId = box.read("userId");

      final receiverId = (myId ==
          chatController.chatType.value
              ?.members?[0].userId)
          ? (chatController.chatType.value
          ?.members?[1].userId!)
          : (chatController.chatType.value
          ?.members?[0].userId!);

      bool ok = await messageController.sendMessageWs(
        chatId: chatId!,
        content: msgController.text.trim(), recipientId: receiverId!,
      );

      if (ok) {
        msgController.clear();
        // chatController.loadMessages(chatId!); // reload after sending
      }
    }

    Future<void> deleteMessage(int index) async {
      bool ok = await messageController.deleteMessage(
          chatId!, chatController.messages[index].id);
      if (ok) {
        // chatController.loadMessages(chatId!); // reload after delete
      }
    }

    void editMessage(Message msg) async {
      final updateController = TextEditingController(text: msg.content);

      Dialogs.editProfile(
        context,
        updateController,
        "Message",
        () async {
          bool ok = await messageController.updateMessage(
            chatId: chatId!,
            messageId: msg.id,
            newContent: updateController.text,
          );
          if (ok) {
            Get.back();
            // chatController.loadMessages(chatId!); // reload messages
          }
        },
      );
    }

    final box = GetStorage();
    final myId = box.read("userId");

    // final myId = profileController.user.value?.id;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        Get.delete<ChatScreenController>();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          toolbarHeight: 0,
        ),
        body: Stack(
          children: [
            Obx(() => Positioned.fill(
              child: chatBackground(
                chatController.chatType.value?.backgroundImageUrl,
              ),
            ),),

            // for bright background
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
              ),
            ),
            Column(
              children: [
                Container(
                  height: 85,
                  padding: EdgeInsets.only(
                      left: Get.width * 0.02, right: Get.width * 0.04),
                  decoration: BoxDecoration(
                      color: Color(0xff2A2A2A),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      )),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: Get.width * 0.03,
                          children: [
                            IconButton(
                              onPressed: () {
                                Get.back();
                              },
                              icon: Icon(Icons.arrow_back),
                              color: AppColors.white,
                            ),
                            chatController.isLoading.value
                                ? shimmerHeader()
                                : InkWell(
                                    onTap: () {
                                      Get.to(
                                          () => chatController.type.value == "GROUP"
                                              ? GroupProfileScreen()
                                              : ProfileScreen(
                                                  id: myId ==
                                                          chatController
                                                              .chatType
                                                              .value
                                                              ?.members?[0]
                                                              .userId
                                                      ? (chatController
                                                          .chatType
                                                          .value
                                                          ?.members?[1]
                                                          .userId!)
                                                      : (chatController
                                                          .chatType
                                                          .value
                                                          ?.members?[0]
                                                          .userId!),
                                            isFromGroup: false,
                                                ));
                                    },
                                    child:
                                        Row(spacing: Get.width * 0.04, children: [
                                      ProfileAvatar(
                                          imageUrl:
                                              chatController.type.value == "GROUP"
                                                  ? chatController.chatType.value
                                                          ?.groupImageUrl ??
                                                      ''
                                                  : myId ==
                                                          chatController
                                                              .chatType
                                                              .value
                                                              ?.members?[0]
                                                              .userId
                                                      ? (chatController
                                                              .chatType
                                                              .value
                                                              ?.members?[1]
                                                              .profileImageUrl) ??
                                                          ''
                                                      : chatController
                                                              .chatType
                                                              .value
                                                              ?.members?[0]
                                                              .profileImageUrl ??
                                                          '',
                                          radius: 25),
                                      // SizedBox(
                                      //   width: Get.width * 0.04,
                                      // ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: Get.width * 0.25,
                                            child: chatController.type.value ==
                                                    "GROUP"
                                                ? Text(
                                                    chatController
                                                            .chatType.value?.name ??
                                                        '',
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 16,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        color: AppColors.white),
                                                  )
                                                : Text(
                                                    myId ==
                                                            chatController
                                                                .chatType
                                                                .value
                                                                ?.members?[0]
                                                                .userId
                                                        ? ("${chatController.chatType.value?.members?[1].firstName} ${chatController.chatType.value?.members?[1].lastName}") ??
                                                            ''
                                                        : ("${chatController.chatType.value?.members?[0].firstName} ${chatController.chatType.value?.members?[0].lastName}") ??
                                                            '',
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 16,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        color: AppColors.white),
                                                  ),
                                          ),
                                          Text(
                                            "Online",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 12,
                                              color: AppColors.white.withAlpha(220),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                                  ),
                          ],
                        ),
                        chatController.type.value == "GROUP"
                            ? SizedBox()
                            : Row(
                                children: [
                                  messageController.isVoiceCallOn.value
                                      ? SizedBox(
                                          width: Get.width * 0.04,
                                          height: Get.width * 0.04,
                                          child: CircularProgressIndicator(
                                              color: Colors.white),
                                        )
                                      : InkWell(
                                          onTap: () {
                                            final channelId = chatId;
                                            debugPrint('StartCAll :-   $channelId');
                                            final receiverId = (myId ==
                                                    chatController.chatType.value
                                                        ?.members?[0].userId)
                                                ? (chatController.chatType.value
                                                    ?.members?[1].userId!)
                                                : (chatController.chatType.value
                                                    ?.members?[0].userId!);
                                            final receiverName = myId ==
                                                    chatController.chatType.value
                                                        ?.members?[0].userId
                                                ? ("${chatController.chatType.value?.members?[1].firstName} ${chatController.chatType.value?.members?[1].lastName}") ??
                                                    ''
                                                : ("${chatController.chatType.value?.members?[0].firstName} ${chatController.chatType.value?.members?[0].lastName}") ??
                                                    '';

                                            messageController.startCall(
                                                receiverName,
                                                receiverId.toString(),
                                                channelId.toString(),
                                                false,
                                                context);
                                          },
                                          child: CircleAvatar(
                                            radius: Get.width * 0.05,
                                            backgroundColor: Colors.white,
                                            child: Image.asset(
                                                "assets/images/chat_call.png",
                                                scale: 2),
                                          ),
                                        ),
                                  SizedBox(
                                    width: Get.width * 0.05,
                                  ),
                                  messageController.isVideoCallOn.value
                                      ? SizedBox(
                                          width: Get.width * 0.04,
                                          height: Get.width * 0.04,
                                          child: CircularProgressIndicator(
                                              color: Colors.white),
                                        )
                                      : InkWell(
                                          onTap: () {
                                            final channelId = chatId;
                                            debugPrint('StartCAll :-   $channelId');
                                            final receiverId = (myId ==
                                                    chatController.chatType.value
                                                        ?.members?[0].userId)
                                                ? (chatController.chatType.value
                                                    ?.members?[1].userId!)
                                                : (chatController.chatType.value
                                                    ?.members?[0].userId!);
                                            final receiverName = myId ==
                                                    chatController.chatType.value
                                                        ?.members?[0].userId
                                                ? ("${chatController.chatType.value?.members?[1].firstName} ${chatController.chatType.value?.members?[1].lastName}") ??
                                                    ''
                                                : ("${chatController.chatType.value?.members?[0].firstName} ${chatController.chatType.value?.members?[0].lastName}") ??
                                                    '';

                                            messageController.startCall(
                                                receiverName,
                                                receiverId.toString(),
                                                channelId.toString(),
                                                true,
                                                context);
                                          },
                                          child: CircleAvatar(
                                            radius: Get.width * 0.05,
                                            backgroundColor: Colors.white,
                                            child: Image.asset(
                                              "assets/images/chat_videocall.png",
                                              scale: 2,
                                            ),
                                          ),
                                        ),
                                ],
                              )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () =>
                        ListView.builder(
                          itemCount: chatController.messages.length,
                          reverse: true,
                          padding: EdgeInsets.only(
                              top: Get.height * .01,
                              left: Get.width * 0.05,
                              right: Get.width * 0.05),
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {

                            final isMyMessage = chatController
                                .messages[
                            chatController.messages.length - index - 1]
                                .senderId ==
                                myId;
                            // debugPrint("Index ${index}");
                            return GestureDetector(
                              onDoubleTap: isMyMessage &&
                                  chatController.messages[chatController.messages.length - index - 1]
                                      .sentAt
                                      .isAfter(DateTime.now().subtract(const Duration(minutes: 5)))
                                  ? () {
                                editMessage(chatController.messages[
                                chatController.messages.length - index - 1]);
                              } : null,
                              onLongPress: isMyMessage ? () {
                                showCupertinoModalPopup(
                                  // barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return CupertinoActionSheet(
                                      title: Text("Delete Message"),
                                      message: Text(
                                          "Are you sure you want to delete this message?"),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          child: Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () {
                                            deleteMessage(
                                                chatController.messages.length -
                                                    index -
                                                    1);
                                            Navigator.pop(context);
                                          },
                                        ),
                                        CupertinoActionSheetAction(
                                          child: Text("Cancel"),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }: null,
                              child: MessageCard(
                                message: chatController.messages[
                                chatController.messages.length - index - 1],
                                isMe: chatController
                                    .messages[
                                chatController.messages.length - index - 1]
                                    .senderId ==
                                    myId,
                                onDownload: () => chatController.downloadMedia(
                                    chatController.messages[
                                    chatController.messages.length - index - 1]),
                              ),
                            );
                          },
                        ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Get.width * 0.05, vertical: 5),
                  child: SizedBox(
                    width: double.infinity,
                    // height: 44,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: AppColors.white),
                            focusNode: messageController.focusNode,
                            controller: msgController,
                            maxLines: 5,
                            minLines: 1,
                            cursorColor: AppColors.white,
                            decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.primary,
                                prefixIcon: IconButton(
                                  padding: EdgeInsets.only(bottom: 0),
                                  onPressed: messageController.toggleEmojiPicker,
                                  icon: Icon(
                                    Icons.emoji_emotions_outlined,
                                    color: AppColors.white.withAlpha(200),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    // messageController.pickImage(
                                    //     ImageSource.gallery, chatId!);
                                    showAttachmentMenu(context, attachKey);
                                  },
                                  icon: Icon(
                                    Icons.attach_file,
                                    color: AppColors.white,
                                  ),
                                ),
                                hintText: "Type a message . . .",
                                hintStyle: TextStyle(
                                    color: AppColors.white.withAlpha(155)),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(20),
                                )),
                          ),
                        ),
                        SizedBox(
                          width: Get.width * 0.02,
                        ),
                        Obx(
                          () => messageController.isLoading.value
                              ? SizedBox(
                                  height: Get.height * 0.045,
                                  width: Get.width * 0.12,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: Get.height * 0.045,
                                  width: Get.width * 0.12,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: InkWell(
                                      key: attachKey,
                                      onTap: sendMessage,
                                      child: Icon(
                                        Icons.send,
                                        size: Get.width * 0.05,
                                        color: AppColors.white,
                                      )),

                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  //   children: [
                                  //     InkWell(
                                  //         onTap: _sendMessage,
                                  //         child:
                                  //         Image.asset(
                                  //           "assets/images/chat_add.png",
                                  //           scale: 2,
                                  //         ),
                                  //     ),
                                  //     Image.asset(
                                  //       "assets/images/chat_mic.png",
                                  //       scale: 2,
                                  //     ),
                                  //   ],
                                  // ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Obx(() => Offstage(
                      offstage: !messageController.isEmojiVisible.value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: EmojiPicker(
                          textEditingController: msgController,
                          config: Config(
                              height: 280,
                              checkPlatformCompatibility: true,
                              emojiViewConfig: EmojiViewConfig(
                                columns: 7,
                                emojiSizeMax: 25,
                                backgroundColor: Colors.transparent,
                              ),
                              categoryViewConfig: CategoryViewConfig(
                                backgroundColor: Colors.transparent,
                                indicatorColor: AppColors.primary,
                                iconColorSelected: AppColors.primary,
                              ),
                              bottomActionBarConfig:
                                  BottomActionBarConfig(enabled: false)),
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem _popupItem(IconData icon, String title, VoidCallback onTap) {
    return PopupMenuItem(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 14),
          )
        ],
      ),
    );
  }
}

Widget shimmerHeader() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade600,
    highlightColor: Colors.grey.shade100,
    child: Row(
      spacing: Get.width * 0.04,
      children: [
        // Avatar shimmer
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Name shimmer
            Container(
              width: Get.width * 0.25,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),

            // Status shimmer
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
              ),
            ),
          ],
        )
      ],
    ),
  );
}

Widget chatBackground(String? bgUrl) {
  //Default
  if (bgUrl == null || bgUrl.isEmpty) {
    return Image.asset(
      "assets/images/chat_bg_default.png",
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  // Network Background
  return Image.network(
    bgUrl,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) {
      return Image.asset(
        "assets/images/chat_bg_default.png",
        fit: BoxFit.cover,
      );
    },
  );
}
