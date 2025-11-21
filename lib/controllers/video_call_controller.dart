import 'dart:async';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoCallController extends GetxController {
  final String channelId;
  final String token;
  final String callerId;
  final String receiverId;

  VideoCallController({
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.receiverId,
  });

  late RtcEngine _engine;
  int? remoteUid;
  final profileController = Get.find<ProfileController>();
  final messageController = Get.put(MessageController());

  // State variables
  var isMuted = false.obs;
  var isVideoOff = false.obs;
  var isRemoteVideoOff = false.obs;
  var localUserJoined = false.obs;
  var isConnected = false.obs;
  var callDuration = Duration.zero.obs;
  var showControls = true.obs;
  var isLocalMain = false.obs;
  RxDouble localVideoX = 20.0.obs;
  RxDouble localVideoY = 50.0.obs;

  Timer? _timer;
  Timer? _hideTimer;

  @override
  void onInit() {
    super.onInit();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    await _engine.enableVideo();
    await _engine.startPreview();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          localUserJoined.value = true;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          this.remoteUid = remoteUid;
          isRemoteVideoOff.value = false;
          isConnected.value = true;
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          if (this.remoteUid == remoteUid) {
            this.remoteUid = null;
            isRemoteVideoOff.value = false;
          }
          endCallForBoth();
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          if (this.remoteUid == remoteUid) {
            isRemoteVideoOff.value = muted;
          }
        },
      ),
    );

    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: profileController.user.value!.id!,
    );
  }

  void swapVideos() {
    isLocalMain.value = !isLocalMain.value;
  }

  void toggleMute() async {
    isMuted.value = !isMuted.value;
    await _engine.muteLocalAudioStream(isMuted.value);
  }

  void toggleVideo() async {
    isVideoOff.value = !isVideoOff.value;
    await _engine.updateChannelMediaOptions(
      ChannelMediaOptions(publishCameraTrack: !isVideoOff.value),
    );
  }

  void switchCamera() async => await _engine.switchCamera();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value = callDuration.value + const Duration(seconds: 1);
    });
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  void startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      showControls.value = false;
    });
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) startHideTimer();
  }

  Future<void> endCallForBoth() async {
    _timer?.cancel();
    await messageController.endCall(
      channelId: channelId,
      callerId: callerId,
      receiverId: receiverId,
    );
    await _engine.leaveChannel();
    await _engine.release();
    FlutterCallkitIncoming.endAllCalls();

    // for reset everything
    Get.delete<VideoCallController>();

    if (Navigator.canPop(Get.context!)) {
      Navigator.pop(Get.context!);
    }
    else{
      Get.offAll(()=> MainScreen());
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.onClose();
  }

  RtcEngine get engine => _engine;
}
