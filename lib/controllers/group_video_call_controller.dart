import 'dart:async';
import 'dart:ui';
import 'package:chatify/services/floating_call_bubble_service.dart';
import 'package:chatify/sound_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../constants/apis.dart';
import '../controllers/message_controller.dart';
import '../controllers/profile_controller.dart';

class GroupVideoCallController extends GetxController {
  final String channelId;
  final String token;
  final String callerId;
  final List<dynamic> receiverIds;

  GroupVideoCallController({
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
  final isVideoOff = false.obs;
  final isConnected = false.obs;
  final localUserJoined = false.obs;
  final isCallActive = true.obs;

  // ===== Small video (gesture) state =====
  final isLocalMain = false.obs;

  final localVideoX = 20.0.obs;
  final localVideoY = 50.0.obs;

// Screen size (set from UI once)
  late Size screenSize;


  final remoteUids = <int>{}.obs;
  final remoteVideoStates = <int, bool>{}.obs;
  final participantNames = <int, String>{}.obs;

  final callDuration = Duration.zero.obs;
  Timer? _timer;

  // UI helpers
  final showControls = true.obs;
  Timer? _hideTimer;

  final callUIState = CallUIState.calling.obs;

  // Add this inside GroupVideoCallController class

  final isScreenSharing = false.obs;

  Future<void> startScreenShare() async {
    try {
      // 1. Start screen capture with desired parameters
      await engine.startScreenCapture(
        const ScreenCaptureParameters2(
          captureAudio: true,
          captureVideo: true,
          videoParams: ScreenVideoParameters(
            dimensions: VideoDimensions(width: 720, height: 1280),
            frameRate: 15,
            bitrate: 2000,
          ),
        ),
      );

      // 2. Update channel media options to publish the screen track instead of camera
      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: false,         // Stop publishing camera
          publishMicrophoneTrack: true,      // Keep audio active
          publishScreenCaptureVideo: true,   // Publish screen video
          publishScreenCaptureAudio: true,   // Publish screen audio (if needed)
        ),
      );

      isScreenSharing.value = true;
    } catch (e) {
      debugPrint("Error starting screen share: $e");
    }
  }

  Future<void> stopScreenShare() async {
    try {
      // 1. Stop the capture
      await engine.stopScreenCapture();

      // 2. Revert media options back to the camera
      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,          // Resume camera
          publishMicrophoneTrack: true,
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
        ),
      );

      isScreenSharing.value = false;
    } catch (e) {
      debugPrint("Error stopping screen share: $e");
    }
  }

  // ===== Lifecycle =====
  @override
  void onInit() {
    super.onInit();

    for (var user in receiverIds) {
      participantNames[user['id']] =
      "${user['firstName']} ${user['lastName']}";
    }
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
    // If already connected, ignore
    if (callUIState.value == CallUIState.connected) return;

    callUIState.value = CallUIState.timeout;

    //
    SoundManager().stop();

    _timer?.cancel();

    try {
      await engine.leaveChannel();
    } catch (_) {}

    // End system call UI
    FlutterCallkitIncoming.endAllCalls();
  }

  void onLocalPanUpdate(DragUpdateDetails details) {
    localVideoX.value =
        (localVideoX.value + details.delta.dx)
            .clamp(0.0, screenSize.width - screenSize.width * 0.3);

    localVideoY.value =
        (localVideoY.value + details.delta.dy)
            .clamp(0.0, screenSize.height - screenSize.height * 0.2);
  }

  void onLocalPanEnd() {
    final targetX = localVideoX.value < screenSize.width / 2
        ? 16.0
        : screenSize.width - screenSize.width * 0.3 - 16.0;

    final targetY = localVideoY.value.clamp(
      50.0,
      screenSize.height - screenSize.height * 0.2 - 120,
    );

    localVideoX.value = targetX;
    localVideoY.value = targetY;
  }

  void swapVideos() {
    isLocalMain.toggle();
  }


  // ===== Init =====
  Future<void> _startCall() async {
    await _initAgora();
    await _setupLocalVideo();
    _registerEvents();
    await _joinChannel();
  }

  Future<void> _initAgora() async {
    engine = createAgoraRtcEngine();
    await engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> _setupLocalVideo() async {
    await engine.enableVideo();
    await engine.startPreview();
  }

  void _registerEvents() {
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          localUserJoined.value = true;
        },
        onUserJoined: (_, uid, __) {
          remoteUids.add(uid);
          isConnected.value = true;
          callUIState.value = CallUIState.connected;
          SoundManager().stop();
          if (callDuration.value == Duration.zero) _startTimer();
        },
        onUserOffline: (_, uid, __) {
          remoteUids.remove(uid);
          remoteVideoStates.remove(uid);

          if (remoteUids.isEmpty) {
            endCall();
          }
        },
        onUserMuteVideo: (_, uid, muted) {
          remoteVideoStates[uid] = muted;
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
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
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

  void toggleVideo() async {
    isVideoOff.toggle();
    await engine.updateChannelMediaOptions(
      ChannelMediaOptions(
        publishCameraTrack: !isVideoOff.value,
      ),
    );
  }

  void switchCamera() async {
    await engine.switchCamera();
  }

  // ===== Controls visibility =====
  void toggleControls() {
    showControls.toggle();
    if (showControls.value) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      showControls.value = false;
    });
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
    Get.delete<GroupVideoCallController>(force: true);

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
      await engine.stopPreview();
      await engine.release();
    } catch (_) {}
  }
}

enum CallUIState {
  calling,
  connected,
  timeout,
}