import 'dart:async';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get_storage/get_storage.dart';

import '../services/floating_call_bubble_service.dart';


class VoiceCallController extends GetxController with WidgetsBindingObserver {
  final String channelId;
  final String token;
  final String callerId;
  final String receiverId;
  final String name;

  VoiceCallController(
      {required this.channelId,
      required this.token,
      required this.callerId,
      required this.receiverId,
      required this.name});

  final messageController = Get.put(MessageController());

  late RtcEngine _engine;
  Timer? _timer;

  // Reactive states
  final isMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isConnected = false.obs;
  final localUserJoined = false.obs;
  final callDuration = Duration.zero.obs;
  final remoteUid = RxnInt();

  // For bubble
  RxString callerName = ''.obs;
  final bubbleX = 20.0.obs;
  final bubbleY = 150.0.obs;

  final box = GetStorage();

  bool _isCallActive = true;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initAgora();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("APP MINIMIZED — CALL STILL RUNNING");
      // FloatingCallBubbleService.to.isVisible.value = true;
      // Do NOT end call
    }

    if (state == AppLifecycleState.resumed) {
      print("APP RESUMED — RESTORE CALL UI");
    }
  }


  Future<void> _initAgora() async {
    callerName.value = name;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        localUserJoined.value = true;
      },
      onUserJoined: (connection, uid, elapsed) {
        remoteUid.value = uid;
        isConnected.value = true;
        _startTimer();
      },
      onUserOffline: (connection, uid, reason) {
        if (uid == remoteUid.value) {
          remoteUid.value = null;
        }
        endCall();
      },
    ));

    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: box.read("userId"),
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  void toggleMute() async {
    isMuted.toggle();
    await _engine.muteLocalAudioStream(isMuted.value);
  }

  void toggleSpeaker() async {
    isSpeakerOn.toggle();
    await _engine.setEnableSpeakerphone(isSpeakerOn.value);
  }

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

  Future<void> endCall() async {
    if (!_isCallActive) return;
    _isCallActive = false;

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
    Get.delete<VoiceCallController>(force: true);

    // if (Get.isOverlaysOpen) Get.back();
    if (Navigator.canPop(Get.context!)) {
      Navigator.pop(Get.context!);
    } else {
      Get.offAll(() => MainScreen());
    }
    FloatingCallBubbleService.to.hide();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.onClose();
  }
}
