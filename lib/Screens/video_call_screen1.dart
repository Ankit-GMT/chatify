import 'package:chatify/controllers/video_call_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoCallScreen1 extends StatelessWidget {
  final String channelId;
  final String token;
  final String callerId;
  final String receiverId;

  const VideoCallScreen1({
    super.key,
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VideoCallController(
      channelId: channelId,
      token: token,
      callerId: callerId,
      receiverId: receiverId,
    ));

    return Obx(() {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: controller.toggleControls,
          child: Stack(
            children: [
              // Main Video
              Center(
                child: controller.remoteUid != null
                    ? controller.isRemoteVideoOff.value
                    ? const Icon(Icons.videocam_off, size: 80, color: Colors.white70)
                    : AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: controller.engine,
                    canvas: VideoCanvas(uid: controller.remoteUid),
                    connection: RtcConnection(channelId: channelId),
                  ),
                )
                    : const Center(
                  child: Text(
                    'Waiting for remote user...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              // Local Preview (small)
              if (controller.localUserJoined.value)
                Positioned(
                  right: 20,
                  top: 40,
                  width: 100,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: controller.isVideoOff.value
                        ? Container(
                      color: Colors.black54,
                      child: const Icon(Icons.videocam_off, color: Colors.white),
                    )
                        : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: controller.engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),

              // Call Info
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: controller.showControls.value ? 40 : -100,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text("John Doe",
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      controller.isConnected.value
                          ? controller.formatDuration(controller.callDuration.value)
                          : "Calling…",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Bottom Control Buttons
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                bottom: controller.showControls.value ? Get.height * 0.06 : -Get.height * 0.07,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: controller.showControls.value ? 1 : 0,
                  child: !controller.localUserJoined.value
                      ? SizedBox()
                      : Center(
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
                          spacing: 5,
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _controlButton(
                              icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                              onPressed: controller.toggleMute,
                            ),
                            VerticalDivider(
                              color: Colors.white38,
                              thickness: 1,
                              indent: 15,
                              endIndent: 15,
                            ),
                            _controlButton(
                              icon: Icons.call_end,
                              color: Colors.redAccent,
                              onPressed: controller.endCallForBoth,
                            ),
                            VerticalDivider(
                              color: Colors.white38,
                              thickness: 1,
                              indent: 15,
                              endIndent: 15,
                            ),
                            _controlButton(
                              icon: Icons.cameraswitch,
                              onPressed: controller.switchCamera,
                            ),
                            VerticalDivider(
                              color: Colors.white38,
                              thickness: 1,
                              indent: 15,
                              endIndent: 15,
                            ),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

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
}
