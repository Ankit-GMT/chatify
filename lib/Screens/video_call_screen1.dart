import 'dart:ui' as ui;

import 'package:android_pip/android_pip.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/video_call_controller.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey _ssKey = GlobalKey();

class VideoCallScreen1 extends StatefulWidget {
  final String channelId;
  final String token;
  final String callerId;
  final String receiverId;
  final String name;

  const VideoCallScreen1({
    super.key,
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.receiverId,
    required this.name,
  });

  @override
  State<VideoCallScreen1> createState() => _VideoCallScreen1State();
}

class _VideoCallScreen1State extends State<VideoCallScreen1>
    with WidgetsBindingObserver {
  static const pipChannel = MethodChannel("chatify/pip");

  void enablePipMode() async {
    await pipChannel.invokeMethod("enablePip");
  }

  void disablePipMode() async {
    await pipChannel.invokeMethod("disablePip");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    enablePipMode(); // allow PiP

    // Listen to pip status from MainActivity
    pipChannel.setMethodCallHandler((call) async {
      if (call.method == "pipStatus") {
        bool isPip = call.arguments as bool;
        isPipMode.value = isPip;
        return;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disablePipMode(); // stop PiP
    super.dispose();
  }

  // bool pipTriggered = false;
  var isPipMode = false.obs;

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   print("LIFECYCLE: $state");

  //   if (!pipTriggered && state == AppLifecycleState.inactive) {
  //     pipTriggered = true;
  //
  //     // Future.delayed(Duration(milliseconds: 80), () {
  //       enterPiP();
  //     // });
  //   }
  // }

  Future<void> enterPiP() async {
    final pip = AndroidPIP();

    await pip.enterPipMode(
      aspectRatio: const [9, 16],
      autoEnter: false,
    );
  }

  Future<void> _captureScreenshot() async {
    try {
      await Permission.photos.request();
      await Permission.storage.request();

      final boundary =
          _ssKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "chatify_screenshot_${DateTime.now().millisecondsSinceEpoch}",
      );

      debugPrint("Gallery save result: $result");

      // success
      Get.snackbar(
        "Screenshot Saved",
        "Saved to Gallery",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint("Screenshot error: $e");

      // Error
      CustomSnackbar.error(
        "Failed",
        "Could not save screenshot",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
        VideoCallController(
          channelId: widget.channelId,
          token: widget.token,
          callerId: widget.callerId,
          receiverId: widget.receiverId,
          name: widget.name
        ),
        permanent: true);

    return Obx(() {
      // Recompute inside Obx so reactive values (isLocalMain, etc.) rebuild correctly
      final mainVideo = controller.isLocalMain.value
          ? _localVideo(controller)
          : _remoteVideo(controller);
      final smallVideo = controller.isLocalMain.value
          ? _remoteVideo(controller)
          : _localVideo(controller);

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // if(!didPop){
          //   enterPiP();
          // }
          if (!didPop && !controller.isScreenSharing.value) {
            enterPiP();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white70,
          body: GestureDetector(
            onTap: controller.toggleControls,
            child: Stack(
              children: [
                /// MAIN VIDEO
                Center(child: mainVideo),

                /// LOCAL SMALL PREVIEW (draggable + swap)
                if (controller.localUserJoined.value ||
                    controller.remoteUid != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: controller.localVideoX.value,
                    top: controller.localVideoY.value,
                    width: Get.width * 0.3,
                    height: Get.height * 0.2,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        controller.localVideoX.value =
                            (controller.localVideoX.value + details.delta.dx)
                                .clamp(0.0, Get.width - Get.width * 0.3);
                        controller.localVideoY.value =
                            (controller.localVideoY.value + details.delta.dy)
                                .clamp(0.0, Get.height - Get.height * 0.2);
                      },
                      onPanEnd: (details) {
                        final screenWidth = Get.width;
                        final targetX =
                            controller.localVideoX.value < screenWidth / 2
                                ? 16.0
                                : screenWidth - Get.width * 0.3 - 16.0;
                        final targetY = controller.localVideoY.value.clamp(
                          50.0,
                          Get.height - Get.height * 0.2 - 100.0,
                        );
                        controller.localVideoX.value = targetX;
                        controller.localVideoY.value = targetY;
                      },
                      onTap: controller.swapVideos,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black54,
                          child: smallVideo,
                        ),
                      ),
                    ),
                  ),

                /// CALL INFO (Name + Duration)
                !isPipMode.value
                    ? AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        top: controller.showControls.value
                            ? Get.height * 0.06
                            : -Get.height * 0.07,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(widget.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 6),
                            Obx(() {
                              switch (controller.callUIState.value) {
                                case CallUIState.calling:
                                  return Text(
                                    "Calling…",
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16),
                                  );

                                case CallUIState.connected:
                                  return Text(
                                    controller.formatDuration(
                                        controller.callDuration.value),
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 16),
                                  );

                                case CallUIState.timeout:
                                  return const Text(
                                    "No answer",
                                    style: TextStyle(
                                        color: Colors.redAccent, fontSize: 16),
                                  );
                              }
                            }),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),

                /// SCREEN SHARING INDICATOR OVERLAY
                Obx(() {
                  if (controller.isScreenSharing.value) {
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.8),
                        // Dim the background
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.screen_share,
                              size: 80,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "You are sharing your screen",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Everything on your screen is visible to others.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: () => controller.stopScreenShare(),
                              icon: const Icon(Icons.stop),
                              label: const Text("Stop Sharing"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox
                      .shrink(); // Return nothing if not sharing
                }),

                /// BOTTOM CONTROL BUTTONS
                !isPipMode.value
                    ? AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        bottom: controller.showControls.value
                            ? Get.height * 0.06
                            : -Get.height * 0.07,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: controller.showControls.value ? 1 : 0,
                          child: controller.localUserJoined.value &&
                                  (controller.callUIState.value ==
                                          CallUIState.connected ||
                                      controller.callUIState.value ==
                                          CallUIState.calling)
                              ? Center(
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _controlButton(
                                            icon: controller.isMuted.value
                                                ? Icons.mic_off
                                                : Icons.mic,
                                            onPressed: controller.toggleMute,
                                          ),
                                          _divider(),
                                          _controlButton(
                                            icon: Icons.call_end,
                                            color: Colors.redAccent,
                                            bgColor: AppColors.white,
                                            onPressed:
                                                controller.endCallForBoth,
                                          ),
                                          _divider(),
                                          _controlButton(
                                            icon: Icons.fit_screen_outlined,
                                            color: Colors.tealAccent,
                                            onPressed: () {
                                              _captureScreenshot();
                                            },
                                          ),
                                          _divider(),
                                          _controlButton(
                                            icon: Icons.cameraswitch,
                                            onPressed: controller.switchCamera,
                                          ),
                                          _divider(),
                                          _controlButton(
                                            icon: controller.isVideoOff.value
                                                ? Icons.videocam_off
                                                : Icons.videocam,
                                            onPressed: controller.toggleVideo,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : controller.callUIState.value ==
                                      CallUIState.timeout
                                  ? Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 100),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppColors.white,
                                              child: _controlButton(
                                                icon: Icons.close,
                                                onPressed: () {
                                                  NotificationService()
                                                      .localNotifications
                                                      .cancel(999);

                                                  Get.delete<
                                                          VideoCallController>(
                                                      force: true);
                                                  Navigator.pop(
                                                      context, [false]);
                                                },
                                                color: AppColors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 40),
                                            CircleAvatar(
                                              backgroundColor: AppColors.white,
                                              child: _controlButton(
                                                icon: Icons.refresh,
                                                onPressed: () {
                                                  controller.retryCall();
                                                },
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      )
                    : const SizedBox.shrink(),
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 150,
                  child:
                      // In your control buttons section:
                      SizedBox(
                        width: Get.width *0.2,
                        child: _controlButton(
                                            icon: controller.isScreenSharing.value
                          ? Icons.stop_screen_share
                          : Icons.screen_share,
                                            color: controller.isScreenSharing.value
                          ? Colors.redAccent
                          : Colors.white,
                                            onPressed: () async {
                        if (controller.isScreenSharing.value) {
                          await controller.stopScreenShare();
                        } else {
                          await controller.startScreenShare();
                        }
                                            },
                                          ),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// LOCAL VIDEO
  Widget _localVideo(VideoCallController controller) {
    return Obx(() {
      if (controller.isVideoOff.value) {
        return const Center(
          child: Icon(Icons.videocam_off, size: 40, color: Colors.white70),
        );
      }
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: controller.engine,
          canvas: const VideoCanvas(
            uid: 0,
            renderMode: RenderModeType.renderModeHidden,
          ),
        ),
      );
    });
  }

  /// REMOTE VIDEO
  Widget _remoteVideo(VideoCallController controller) {
    if (controller.remoteUid == null) {
      return const Center(
        child: Text(
          'Waiting for remote user to join...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Only rebuild when remote video toggles
    return Obx(() {
      if (controller.isRemoteVideoOff.value) {
        return const Center(
          child: Icon(Icons.videocam_off, size: 80, color: Colors.white70),
        );
      }
      return RepaintBoundary(
        key: _ssKey,
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: controller.engine,
            canvas: VideoCanvas(
                uid: controller.remoteUid,
                sourceType: VideoSourceType.videoSourceRemote),
            connection: RtcConnection(channelId: controller.channelId),
          ),
        ),
      );
    });
  }

  /// Control Button Widget
  Widget _controlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color bgColor = Colors.transparent
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      color: bgColor,
      onPressed: onPressed,
    );
  }

  /// Divider between control buttons
  Widget _divider() => const VerticalDivider(
        color: Colors.white38,
        thickness: 1,
        indent: 15,
        endIndent: 15,
      );
}
