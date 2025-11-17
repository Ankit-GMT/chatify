import 'package:chatify/Screens/group_profile_screen.dart';
import 'package:chatify/Screens/profile_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/widgets/dialog_textfield.dart';
import 'package:chatify/widgets/message_card.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class ChatScreen extends StatelessWidget {
  int? chatId;

  ChatScreen({super.key, this.chatId});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.put(ProfileController());

    final messageController = Get.put(MessageController());

    TextEditingController msgController = TextEditingController();

    Future<void> sendMessage() async {
      if (msgController.text.trim().isEmpty) return;

      bool ok = await messageController.sendMessage(
        chatId: chatId!,
        content: msgController.text.trim(),
      );

      if (ok) {
        msgController.clear();
        messageController.loadMessages(chatId!); // reload after sending
      }
    }

    Future<void> deleteMessage(int index) async {
      bool ok = await messageController.deleteMessage(
          chatId!, messageController.messages[index].id);
      if (ok) {
        messageController.loadMessages(chatId!); // reload after delete
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
            messageController.loadMessages(chatId!); // reload messages
          }
        },
      );
    }

    final type = messageController.chatType.value?.type ?? '';
    final myId = profileController.user.value?.id;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      body: Column(
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
                      messageController.isLoading.value
                          ? shimmerHeader()
                          : InkWell(
                              onTap: () {
                                Get.to(() => type == "GROUP"
                                    ? GroupProfileScreen(
                                        chatType:
                                            messageController.chatType.value,
                                      )
                                    : ProfileScreen(
                                        id: myId ==
                                                messageController.chatType.value
                                                    ?.members?[0].userId
                                            ? (messageController.chatType.value
                                                ?.members?[1].userId!)
                                            : (messageController.chatType.value
                                                ?.members?[0].userId!),
                                      ));
                              },
                              child: Row(spacing: Get.width * 0.04, children: [
                                ProfileAvatar(
                                    imageUrl: type == "GROUP"
                                        ? messageController.chatType.value
                                                ?.groupImageUrl ??
                                            ''
                                        : myId ==
                                                messageController.chatType.value
                                                    ?.members?[0].userId
                                            ? (messageController
                                                    .chatType
                                                    .value
                                                    ?.members?[1]
                                                    .profileImageUrl) ??
                                                ''
                                            : messageController
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: Get.width * 0.25,
                                      child: type == "GROUP"
                                          ? Text(
                                              messageController
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
                                                      messageController
                                                          .chatType
                                                          .value
                                                          ?.members?[0]
                                                          .userId
                                                  ? ("${messageController.chatType.value?.members?[1].firstName} ${messageController.chatType.value?.members?[1].lastName}") ??
                                                      ''
                                                  : ("${messageController.chatType.value?.members?[0].firstName} ${messageController.chatType.value?.members?[0].lastName}") ??
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
                  type == "GROUP"
                      ? SizedBox()
                      : Row(
                          children: [
                            InkWell(
                              onTap: () {
                                final channelId = chatId;
                                print('StartCAll :-   $channelId');
                                final receiverId = (myId ==
                                        messageController
                                            .chatType.value?.members?[0].userId)
                                    ? (messageController
                                        .chatType.value?.members?[1].userId!)
                                    : (messageController
                                        .chatType.value?.members?[0].userId!);
                                final receiverName = myId ==
                                        messageController
                                            .chatType.value?.members?[0].userId
                                    ? ("${messageController.chatType.value?.members?[1].firstName} ${messageController.chatType.value?.members?[1].lastName}") ??
                                        ''
                                    : ("${messageController.chatType.value?.members?[0].firstName} ${messageController.chatType.value?.members?[0].lastName}") ??
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
                            InkWell(
                              onTap: () {
                                final channelId = chatId;
                                print('StartCAll :-   $channelId');
                                final receiverId = (myId ==
                                        messageController
                                            .chatType.value?.members?[0].userId)
                                    ? (messageController
                                        .chatType.value?.members?[1].userId!)
                                    : (messageController
                                        .chatType.value?.members?[0].userId!);
                                final receiverName = myId ==
                                        messageController
                                            .chatType.value?.members?[0].userId
                                    ? ("${messageController.chatType.value?.members?[1].firstName} ${messageController.chatType.value?.members?[1].lastName}") ??
                                        ''
                                    : ("${messageController.chatType.value?.members?[0].firstName} ${messageController.chatType.value?.members?[0].lastName}") ??
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
              () => ListView.builder(
                itemCount: messageController.messages.length,
                reverse: true,
                padding: EdgeInsets.only(
                    top: Get.height * .01,
                    left: Get.width * 0.05,
                    right: Get.width * 0.05),
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onDoubleTap: () {
                      editMessage(messageController.messages[
                          messageController.messages.length - index - 1]);
                    },
                    onLongPress: () {
                      showCupertinoModalPopup(
                        barrierDismissible: false,
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
                                      messageController.messages.length -
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
                    },
                    child: MessageCard(
                      text: messageController
                          .messages[
                              messageController.messages.length - index - 1]
                          .content,
                      isMe: messageController
                              .messages[
                                  messageController.messages.length - index - 1]
                              .senderId ==
                          myId,
                      time: messageController
                          .messages[
                              messageController.messages.length - index - 1]
                          .sentAt
                          .toString(),
                      imageUrl: messageController
                          .messages[
                              messageController.messages.length - index - 1]
                          .senderProfileImageUrl,
                      name:
                          "${messageController.messages[messageController.messages.length - index - 1].senderFirstName} ${messageController.messages[messageController.messages.length - index - 1].senderLastName}",
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: Get.width * 0.05, vertical: 5),
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
                          hintText: "Type a message . . .",
                          hintStyle:
                              TextStyle(color: AppColors.white.withAlpha(155)),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(20),
                          )),
                    ),
                  ),
                  SizedBox(
                    width: Get.width * 0.02,
                  ),
                  Container(
                    height: Get.height * 0.045,
                    width: Get.width * 0.18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                        onTap: sendMessage,
                        child: Icon(
                          Icons.send,
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
