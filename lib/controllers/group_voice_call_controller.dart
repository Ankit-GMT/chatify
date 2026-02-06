import 'dart:async';
import 'package:chatify/services/floating_call_bubble_service.dart';
import 'package:chatify/sound_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../constants/apis.dart';
import '../controllers/message_controller.dart';
import '../controllers/profile_controller.dart';

class GroupVoiceCallController extends GetxController {
  final String channelId;
  final String token;
  final String callerId;
  final List<dynamic> receiverIds;

  GroupVoiceCallController({
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.receiverIds,
  });

  // ===== Dependencies =====
  final messageController = Get.find<MessageController>();
  final profileController = Get.find<ProfileController>();

  // ===== Agora =====
  late RtcEngine engine;

  // ===== Reactive State =====
  final isMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isConnected = false.obs;
  final localUserJoined = false.obs;
  final isCallActive = true.obs;

  final remoteUids = <int>{}.obs;
  final userNames = <int, String>{}.obs;

  final callDuration = Duration.zero.obs;
  Timer? _timer;
  final callUIState = CallUIState.calling.obs;

  // ===== Floating bubble state =====
  final bubbleX = 10.0.obs;
  final bubbleY = 120.0.obs;

// For bubble title
  final groupName = "Group Voice Call".obs;


  // ===== Lifecycle =====
  @override
  void onInit() {
    super.onInit();
    SoundManager().playOutgoing();
    _startCall();
  }

  @override
  void onClose() {
    SoundManager().stop();
    _cleanupAgora();
    super.onClose();
  }

  void onCallTimeout() async {
    if (callUIState.value == CallUIState.connected) return;

    callUIState.value = CallUIState.timeout;

    _timer?.cancel();
    SoundManager().stop();

    try {
      await engine.leaveChannel();
    } catch (_) {}

    FlutterCallkitIncoming.endAllCalls();
  }

  // ===== Init Flow =====
  Future<void> _startCall() async {
    await _initAgora();
    _registerEvents();
    await _joinChannel();
  }

  Future<void> _initAgora() async {
    engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
  }

  void _registerEvents() {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          localUserJoined.value = true;
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          final match = receiverIds.firstWhere(
                (u) => u['id'] == remoteUid,
            orElse: () => {},
          );

          userNames[remoteUid] = match.isNotEmpty
              ? "${match['firstName']} ${match['lastName']}"
              : "User $remoteUid";

          remoteUids.add(remoteUid);
          isConnected.value = true;
          callUIState.value = CallUIState.connected;
          SoundManager().stop();

          if (callDuration.value == Duration.zero) _startTimer();
        },
        onUserOffline: (connection, remoteUid, reason) {
          remoteUids.remove(remoteUid);

          if (remoteUids.isEmpty) {
            endCall();
          }
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    await engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: profileController.user.value!.id!,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  // ===== Controls =====
  void toggleMute() async {
    isMuted.toggle();
    await engine.muteLocalAudioStream(isMuted.value);
  }

  void toggleSpeaker() async {
    isSpeakerOn.toggle();
    await engine.setEnableSpeakerphone(isSpeakerOn.value);
  }

  // ===== Timer =====
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value += const Duration(seconds: 1);
    });
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  // ===== End Call =====
  Future<void> endCall() async {
    if (!isCallActive.value) return;
    isCallActive.value = false;

    await messageController.endGroupCall(
      channelId: channelId,
      callerId: callerId,
      receiverIds: receiverIds.map((e) => e['id'].toString()).toList(),
    );

    _timer?.cancel();
    await _cleanupAgora();

    FlutterCallkitIncoming.endAllCalls();

    // for reset everything
    Get.delete<GroupVoiceCallController>(force: true);

    if (Navigator.canPop(Get.context!)) {
      Navigator.pop(Get.context!);
    }
    // else {
    //   Get.offAll(() => MainScreen());
    // }
    FloatingCallBubbleService.to.hide();
  }

  // ===== Cleanup =====
  Future<void> _cleanupAgora() async {
    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (_) {}
  }

  Future<void> retryCall() async {
    callUIState.value = CallUIState.calling;
    isConnected.value = false;
    callDuration.value = Duration.zero;

    await messageController.reTryGroupCall(
      receiverIds: receiverIds as List<String>,
      callerId: callerId,
      channelId: channelId,
      groupId: int.parse(channelId),
      callerName: profileController.user.value!.firstName!,
      context: Get.context!,
      isVideo: false,
    );
  }
}

enum CallUIState {
  calling,
  connected,
  timeout,
}