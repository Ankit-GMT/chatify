import 'package:chatify/Screens/call_screen.dart';
import 'package:chatify/Screens/group_profile_screen.dart';
import 'package:chatify/Screens/profile_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/widgets/dialog_textfield.dart';
import 'package:chatify/widgets/message_card.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class ChatScreen extends StatefulWidget {
  ChatUser? chatUser;
  ChatType? chatType;

  ChatScreen({super.key, required this.chatUser, required this.chatType});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //
  final profileController = Get.put(ProfileController());
  final messageController = Get.put(MessageController());

  List<Message> messages = [];
  TextEditingController msgController = TextEditingController();

  Future<void> _loadMessages() async {
    final data = await messageController.fetchMessages(widget.chatType!.id!);
    setState(() {
      messages = data;
    });
  }

  Future<void> _sendMessage() async {
    if (msgController.text.trim().isEmpty) return;

    bool ok = await messageController.sendMessage(
      chatId: widget.chatType!.id!,
      content: msgController.text.trim(),
    );

    if (ok) {
      msgController.clear();
      _loadMessages(); // reload after sending
    }
  }

  Future<void> _deleteMessage(int index) async {
    bool ok = await messageController.deleteMessage(
        widget.chatType!.id!, messages[index].id);
    if (ok) {
      _loadMessages(); // reload after delete
    }
  }

  void _editMessage(Message msg) async {
    final updateController = TextEditingController(text: msg.content);

    Dialogs.editProfile(
      context,
      updateController,
      "Message",
      () async {
        bool ok = await messageController.updateMessage(
          chatId: widget.chatType!.id!,
          messageId: msg.id,
          newContent: updateController.text,
        );
        if (ok) {
          Get.back();
          _loadMessages(); // reload messages
        }
      },
    );
  }

  void _startVoiceCall(BuildContext context) {
    final box = GetStorage();
    final userName = box.read("userName") ?? '';
    final userId = box.read("userId") ?? '';

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
              userId: userId,
              userName: userName,
              callID: widget.chatType!.id.toString()),
        ));
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.chatType?.type ?? '';
    final myId = profileController.user.value?.id;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 85,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          height: 85,
          padding:
              EdgeInsets.only(left: Get.width * 0.13, right: Get.width * 0.04),
          decoration: BoxDecoration(
              color: Color(0xff2A2A2A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Get.to(() => type == "GROUP"
                          ? GroupProfileScreen(
                              chatType: widget.chatType,
                            )
                          : ProfileScreen(
                              id: myId == widget.chatType?.members?[0].userId
                                  ? (widget.chatType?.members?[1].userId!)
                                  : (widget.chatType?.members?[0].userId!),
                            ));
                    },
                    child: ProfileAvatar(
                        imageUrl: type == "GROUP"
                            ? widget.chatType?.groupImageUrl ?? ''
                            : myId == widget.chatType?.members?[0].userId
                                ? (widget.chatType?.members?[1]
                                        .profileImageUrl) ??
                                    ''
                                : widget.chatType?.members?[0]
                                        .profileImageUrl ??
                                    '',
                        radius: 25),
                  ),
                  SizedBox(
                    width: Get.width * 0.04,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: Get.width * 0.25,
                        child: type == "GROUP"
                            ? Text(
                                widget.chatType?.name ?? '',
                                maxLines: 1,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis,
                                    color: AppColors.white),
                              )
                            : Text(
                                myId == widget.chatType?.members?[0].userId
                                    ? ("${widget.chatType?.members?[1].firstName} ${widget.chatType?.members?[1].lastName}") ??
                                        ''
                                    : ("${widget.chatType?.members?[0].firstName} ${widget.chatType?.members?[0].lastName}") ??
                                        '',
                                maxLines: 1,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis,
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
                ],
              ),
              Row(
                children: [
                  // InkWell(
                  //   onTap: (){
                  //     _startVoiceCall(context);
                  //   },
                  //   child: CircleAvatar(
                  //     radius: 27,
                  //     backgroundColor: Colors.white,
                  //     child:
                  //         Image.asset("assets/images/chat_call.png", scale: 2),
                  //   ),
                  // ),
                  ZegoSendCallInvitationButton(
                    isVideoCall: true,   // false for voice call
                    resourceID: "zego_call", // keep same for all users
                    invitees: [
                      ZegoUIKitUser(
                        id: '19',      // friend's user id
                        name: 'Ankit',  // optional, just display
                      ),
                    ],
                  ),
                  SizedBox(
                    width: Get.width * 0.05,
                  ),
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      "assets/images/chat_videocall.png",
                      scale: 2,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: Get.width * 0.05, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                reverse: true,
                padding: EdgeInsets.only(top: Get.height * .01),
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onDoubleTap: () {
                      _editMessage(messages[messages.length - index - 1]);
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
                                  _deleteMessage(messages.length - index - 1);
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
                      text: messages[messages.length - index - 1].content,
                      isMe: messages[messages.length - index - 1].senderId ==
                          myId,
                      time: messages[messages.length - index - 1]
                          .sentAt
                          .toString(),
                      imageUrl: messages[messages.length - index - 1]
                          .senderProfileImageUrl,
                      name:
                          "${messages[messages.length - index - 1].senderFirstName} ${messages[messages.length - index - 1].senderLastName}",
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.primary,
                          prefixIcon: IconButton(
                            onPressed: () {},
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
                    height: 44,
                    width: Get.width * 0.18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                        onTap: _sendMessage,
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
          ],
        ),
      ),
    );
  }
}
