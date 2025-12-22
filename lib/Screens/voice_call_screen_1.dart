import 'dart:ui';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/voice_call_controller.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/floating_call_bubble_service.dart';

class VoiceCallScreen1 extends StatelessWidget {
  final String channelId;
  final String token;
  final String callerId;
  final String receiverId;
  final String name;

  const VoiceCallScreen1({
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
      VoiceCallController(
          channelId: channelId,
          token: token,
          callerId: callerId,
          receiverId: receiverId,
          name: name
      ),
      permanent: true,
    );

    final size = MediaQuery
        .of(context)
        .size;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if(result == null)
          {
            FloatingCallBubbleService.to.isVisible.value = true;

          }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff2a2a2a),
                ),
              ),
            ),
            // Background Blur Effects
            Positioned(
              left: size.width * 0.7,
              top: size.height * 0.2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: 228.4, sigmaY: 228.4, tileMode: TileMode.decal),
                child: Container(
                  width: size.width * 0.67,
                  height: size.width * 0.67,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC35E31).withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: size.width * 0.7,
              top: size.height * 0.2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: 228.4, sigmaY: 228.4, tileMode: TileMode.decal),
                child: Container(
                  width: size.width * 0.67,
                  height: size.width * 0.67,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC35E31).withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // Caller Info
            Column(
              children: [
                SizedBox(
                  height: size.height * 0.27,
                ),
                CircleAvatar(
                  radius: size.width * 0.25,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(
                      Icons.person, size: 60, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  switch (controller.callUIState.value) {
                    case CallUIState.calling:
                      return Text(
                        "Calling…",
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 16),
                      );

                    case CallUIState.connected:
                      return Text(
                        controller.formatDuration(
                            controller.callDuration.value),
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 16),
                      );

                    case CallUIState.timeout:
                      return const Text(
                        "No answer",
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      );
                  }
                }),

              ],
            ),

            // Bottom Buttons
            Obx(() {
              return
                controller
                    .localUserJoined.value && (controller.callUIState.value == CallUIState.connected || controller.callUIState.value == CallUIState.calling )
                    ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child:
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _controlButton(
                            icon: controller.isMuted.value
                                ? Icons.mic_off
                                : Icons.mic,
                            onTap: controller.toggleMute,
                          ),
                          _divider(),
                          _controlButton(
                            icon: controller.isSpeakerOn.value
                                ? Icons.volume_up
                                : Icons.volume_off,
                            onTap: controller.toggleSpeaker,
                          ),
                          _divider(),
                          _controlButton(
                            icon: Icons.call_end,
                            onTap: controller.endCall,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    // :
                // controller.callUIState.value == CallUIState.calling ?
                // Align(
                //   alignment: Alignment.bottomCenter,
                //   child: Padding(
                //     padding: const EdgeInsets.only(bottom: 100),
                //     child: _controlButton(
                //       icon: Icons.call_end,
                //       onTap: () {
                //         Navigator.pop(context);
                //       },
                //       color: Colors.redAccent,
                //     ),
                //   ),
                // )
                    : controller.callUIState.value == CallUIState.timeout ?

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                      backgroundColor: AppColors.white,
                          child: _controlButton(
                            icon: Icons.close,
                            onTap:() {
                              NotificationService().localNotifications.cancel(999);
                              FloatingCallBubbleService.to.hide();
                              Get.delete<VoiceCallController>(force: true);
                              Navigator.pop(context,[false]);
                            },
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(width: 40),
                        CircleAvatar(
                          backgroundColor: AppColors.white,
                          child: _controlButton(
                            icon: Icons.refresh,
                            onTap: () {
                              controller.retryCall();
                            },
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink();
            }
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.transparent,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }

  Widget _divider() =>
      const VerticalDivider(
        color: Colors.white38,
        thickness: 1,
        indent: 15,
        endIndent: 15,
      );

  Widget _buildBlurCircle(Size size, Alignment align, Color color) {
    return Align(
      alignment: align,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: size.width * 0.67,
          height: size.width * 0.67,
          decoration: BoxDecoration(
            color: color.withAlpha(140),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
