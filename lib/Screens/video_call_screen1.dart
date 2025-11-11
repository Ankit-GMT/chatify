import 'package:chatify/controllers/video_call_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoCallScreen1 extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = Get.put(
      VideoCallController(
        channelId: channelId,
        token: token,
        callerId: callerId,
        receiverId: receiverId,
      ),
    );

    return Obx(() {
      // Recompute inside Obx so reactive values (isLocalMain, etc.) rebuild correctly
      final mainVideo = controller.isLocalMain.value
          ? _localVideo(controller)
          : _remoteVideo(controller);
      final smallVideo = controller.isLocalMain.value
          ? _remoteVideo(controller)
          : _localVideo(controller);

      return Scaffold(
        backgroundColor: Colors.white70,
        body: GestureDetector(
          onTap: controller.toggleControls,
          child: Stack(
            children: [
              /// MAIN VIDEO
              Center(child: mainVideo),

              /// LOCAL SMALL PREVIEW (draggable + swap)
              if (controller.localUserJoined.value || controller.remoteUid != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: controller.localVideoX.value,
                  top: controller.localVideoY.value,
                  width: Get.width * 0.3,
                  height: Get.height * 0.2,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      controller.localVideoX.value = (controller.localVideoX.value + details.delta.dx)
                          .clamp(0.0, Get.width - Get.width * 0.3);
                      controller.localVideoY.value = (controller.localVideoY.value + details.delta.dy)
                          .clamp(0.0, Get.height - Get.height * 0.2);
                    },
                    onPanEnd: (details) {
                      final screenWidth = Get.width;
                      final targetX = controller.localVideoX.value < screenWidth / 2
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
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                top: controller.showControls.value ? Get.height*0.06 : -Get.height*0.07,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                     Text(name,
                        style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w600,)),
                    const SizedBox(height: 6),
                    Text(
                      controller.isConnected.value
                          ? controller.formatDuration(controller.callDuration.value)
                          : "Calling…",
                      style: TextStyle(color: controller.isConnected.value
                          ? Colors.greenAccent
                          : Colors.grey,
                        fontSize: 16,),
                    ),
                  ],
                ),
              ),

              /// BOTTOM CONTROL BUTTONS
              AnimatedPositioned(
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
                  child: controller.localUserJoined.value
                      ? Center(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black54,
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
                              onPressed: controller.endCallForBoth,
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
                      : const SizedBox.shrink(),
                ),
              ),
            ],
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

      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: controller.engine,
          canvas: VideoCanvas(uid: controller.remoteUid),
          connection: RtcConnection(channelId: controller.channelId),
        ),
      );
    });
  }

  /// Control Button Widget
  Widget _controlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.transparent,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
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
