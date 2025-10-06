import 'package:chatify/widgets/zego_initializer.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String callID;

  const CallScreen({super.key, required this.userId, required this.userName, required this.callID});

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: appId,
      appSign: appSign,
      userID: userId,
      userName: 'user_$userId',
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..turnOnCameraWhenJoining = true
        ..turnOnMicrophoneWhenJoining = true
        ..topMenuBar.isVisible = true
        ..bottomMenuBarConfig = ZegoBottomMenuBarConfig(
          isVisible: true,
          margin: const EdgeInsets.only(bottom: 100),

          buttons: [
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.hangUpButton,
            ZegoCallMenuBarButtonName.chatButton,
            // ZegoCallMenuBarButtonName.beautyEffectButton,
            ZegoCallMenuBarButtonName.switchCameraButton,
          ],
        )
        ..topMenuBar.buttons = [
          ZegoCallMenuBarButtonName.minimizingButton,
          ZegoCallMenuBarButtonName.showMemberListButton,
          ZegoCallMenuBarButtonName.soundEffectButton,
        ],
    );
  }
}
