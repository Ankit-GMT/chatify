import 'package:chatify/Screens/chat_background_picker.dart';
import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/chat_background_controller.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/widgets/custom_box.dart';
import 'package:chatify/widgets/custom_tile.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ProfileScreen extends StatelessWidget {
  final int? id;
  final bool isFromGroup;
  final int? groupChatId;

  const ProfileScreen({super.key, required this.id, required this.isFromGroup,this.groupChatId});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final chatController = Get.find<ChatScreenController>();
    final messageController = Get.put(MessageController());

    final chat = chatController.chatType;
    userController.fetchUserProfile(id!);

    final box = GetStorage();
    final myId = box.read("userId");

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Obx(
            () => Column(
              spacing: 20,
              children: [
                SizedBox(
                  height: Get.height * 0.03,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // GestureDetector(
                    //     onTap: () {
                    //       Get.back();
                    //     },
                    //     child: Image.asset("assets/images/back_icon.png",scale: 3,))
                    IconButton(
                      color: AppColors.iconGrey,
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(AppColors.white),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                      onPressed: () {
                        if (isFromGroup) {
                          chatController
                              .fetchChatType(groupChatId!);
                        }
                        Get.back();
                      },
                      icon: Icon(Icons.arrow_left),
                    ),
                    // IconButton(
                    //   onPressed: () {
                    //     _showChatOptions(context, chat.value!.id!, chat.value!.locked.value);
                    //   },
                    //   icon: Icon(Icons.more_vert),
                    // ),
                    PopupMenuButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(AppColors.white),
                        foregroundColor: WidgetStatePropertyAll(AppColors.black),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                      itemBuilder: (context) {
                        return [
                          if(!chat.value!.locked.value)
                            PopupMenuItem(
                              onTap: () {
                                Get.back();
                                _showSetPinSheet(chat.value!.id!);
                              },
                              child: Row(
                                spacing: 5,
                                children: [
                                  Icon(Icons.lock),
                                  Text("Lock Chat"),
                                ],
                              ),
                            ),
                          if(chat.value!.locked.value)
                            PopupMenuItem(
                              onTap: () {
                                Get.back();
                                _confirmUnlock(chat.value!.id!, chatController);
                              },
                              child: Row(
                                spacing: 5,
                                children: [
                                  Icon(Icons.lock_open),
                                  Text("Unlock Chat"),
                                ],
                              ),
                            ),


                        ];
                      },
                    )
                  ],
                ),
                ProfileAvatar(
                    imageUrl: '${userController.user.value.profileImageUrl}',
                    radius: 50),
                Column(
                  children: [
                    Text(
                      "${userController.user.value.firstName} ${userController.user.value.lastName}",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "+91 ${userController.user.value.phoneNumber}",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomBox(
                      title: "Message",
                      image: "assets/images/profile_message.png",
                      onTap: () {
                        Get.to(()=> ChatScreen(chatId: chat.value!.id!,));
                      },
                    ),
                    CustomBox(
                      title: "Voice Call",
                      isLoading: messageController.isVoiceCallOn.value,
                      image: "assets/images/profile_voice.png",
                      onTap: messageController.isVoiceCallOn.value
                          ? null
                          : () {
                              final channelId = chat.value!.id;
                              debugPrint('StartCAll :-   $channelId');
                              final receiverId =
                                  (myId == chat.value?.members?[0].userId)
                                      ? (chat.value?.members?[1].userId!)
                                      : (chat.value?.members?[0].userId!);
                              final receiverName = myId ==
                                      chat.value?.members?[0].userId
                                  ? ("${chat.value?.members?[1].firstName} ${chat.value?.members?[1].lastName}") ??
                                      ''
                                  : ("${chat.value?.members?[0].firstName} ${chat.value?.members?[0].lastName}") ??
                                      '';

                              messageController.startCall(
                                  receiverName,
                                  receiverId.toString(),
                                  channelId.toString(),
                                  false,
                                  context);
                            },
                    ),
                    CustomBox(
                      title: "Video Call",
                      isLoading: messageController.isVideoCallOn.value,
                      image: "assets/images/profile_video.png",
                      onTap: messageController.isVideoCallOn.value
                          ? null
                          : () {
                              final channelId = chat.value!.id;
                              debugPrint('StartCAll :-   $channelId');
                              final receiverId = (myId ==
                                      chatController
                                          .chatType.value?.members?[0].userId)
                                  ? (chatController
                                      .chatType.value?.members?[1].userId!)
                                  : (chatController
                                      .chatType.value?.members?[0].userId!);
                              final receiverName = myId ==
                                      chatController
                                          .chatType.value?.members?[0].userId
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
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "About",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          userController.user.value.about ?? "No bio",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Media",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    padding: EdgeInsets.only(left: 0),
                    itemBuilder: (context, index) {
                      return Container(
                        height: 70,
                        width: 70,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.network(
                              "https://picsum.photos/200/300",
                              fit: BoxFit.cover,
                            )),
                      );
                    },
                  ),
                ),
                CustomTile(
                  title: "Change Chat Background",
                  image: "assets/images/profile_wallpaper.png",
                  onTap: () {
                    Get.to(
                      () => ChatWallpaperPicker(chatId: chat.value!.id!),
                      binding: BindingsBuilder(() {
                        Get.put(ChatBackgroundController(chat.value!.id!));
                      }),
                    );
                  },
                ),
                CustomTile(
                  title: "Notification",
                  image: "assets/images/profile_notification.png",
                  onTap: () {},
                ),
                CustomTile(
                  title: "Block Number",
                  image: "assets/images/profile_block.png",
                  onTap: () {},
                ),
                CustomTile(
                  title: "Report Number",
                  image: "assets/images/profile_report.png",
                  onTap: () {},
                ),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSetPinSheet(int chatId) {

    String? pin;
    String? confirmPin;

    final chatController = Get.find<ChatScreenController>();

    showDialog(context: Get.context!, builder: (_){
      return Dialog(
        backgroundColor: AppColors.black,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Set a 4-digit PIN to lock this chat",
                style: TextStyle(color: Colors.grey),
              ),
               SizedBox(height: Get.height*0.03),
              Text(
                "Create Pin",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: AppColors.white),
              ),
              SizedBox(height: Get.height*0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
                child: PinCodeTextField(
                  appContext: Get.context!,
                  length: 4,
                  textStyle: TextStyle(color: Colors.black),
                  obscureText: true,
                  onChanged: (value) {
                    pin = value;
                  },
                  onCompleted: (value) {
                    debugPrint("OTP Entered: $value");
                  },
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.black,
                  cursorWidth: 0.5,
                  showCursor: true,
                  cursorHeight: 15,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    fieldOuterPadding: EdgeInsets.symmetric(horizontal: 10),
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: Get.height *0.05,
                    fieldWidth: Get.width *0.1,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    activeColor: Colors.grey.shade400,
                    inactiveColor: Colors.grey.shade300,
                    selectedColor: AppColors.primary,
                    activeBoxShadow: [
                      BoxShadow(
                        color: Color(0xff63636333).withAlpha(51),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  enableActiveFill: true,
                ),
              ),
              SizedBox(height: Get.height*0.01),
              Text(
                "Confirm Pin",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: AppColors.white),
              ),
              SizedBox(height: Get.height*0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
                child: PinCodeTextField(
                  appContext: Get.context!,
                  length: 4,
                  textStyle: TextStyle(color: Colors.black),
                  obscureText: true,
                  onChanged: (value) {
                    confirmPin = value;
                  },
                  onCompleted: (value) {
                    debugPrint("OTP Entered: $value");
                  },
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.black,
                  cursorWidth: 0.5,
                  showCursor: true,
                  cursorHeight: 15,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    fieldOuterPadding: EdgeInsets.symmetric(horizontal: 10),
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: Get.height *0.05,
                    fieldWidth: Get.width *0.1,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    activeColor: Colors.grey.shade400,
                    inactiveColor: Colors.grey.shade300,
                    selectedColor: AppColors.primary,
                    activeBoxShadow: [
                      BoxShadow(
                        color: Color(0xff63636333).withAlpha(51),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  enableActiveFill: true,
                ),
              ),
               SizedBox(height: Get.height*0.02),

              SizedBox(
                width: Get.width*0.6,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () async{
                    if (pin?.length != 4) {
                      CustomSnackbar.error("Error", "PIN must be 4 digits");
                      return;
                    }

                    if (pin != confirmPin) {
                      CustomSnackbar.error("Error", "PINs do not match");
                      return;
                    }

                   await chatController.lockChat(
                      chatId: chatId.toString(),
                      pin: pin!,
                    );
                  },
                  child: const Text("Lock Chat"),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // void _showChatOptions(BuildContext context, int chatId, bool isLocked) {
  //   final chatController = Get.find<ChatScreenController>();
  //
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           if (!isLocked)
  //             ListTile(
  //               leading: const Icon(Icons.lock_outline),
  //               title: const Text("Lock Chat"),
  //               onTap: () {
  //                 Get.back();
  //                 _showSetPinSheet(chatId);
  //               },
  //             ),
  //
  //           if (isLocked)
  //             ListTile(
  //               leading: const Icon(Icons.lock_open),
  //               title: const Text("Unlock Chat"),
  //               onTap: () {
  //                 Get.back();
  //                 _confirmUnlock(chatId, chatController);
  //               },
  //             ),
  //
  //         ],
  //       );
  //     },
  //   );
  // }
  void _confirmUnlock(int chatId, ChatScreenController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text("Remove Chat Lock?"),
        content: const Text(
          "This chat will no longer be protected by a PIN.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              controller.unlockChat(chatId: chatId.toString());
            },
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }



}
