import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/group_voice_call_controller.dart';
import 'package:chatify/services/floating_call_bubble_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupVoiceCallScreen1 extends StatelessWidget {
  final String channelId;
  final String token;
  final String callerId;
  final List<dynamic> receiverIds;

  const GroupVoiceCallScreen1({
    super.key,
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.receiverIds,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
        GroupVoiceCallController(
          channelId: channelId,
          token: token,
          callerId: callerId,
          receiverIds: receiverIds,
        ),
        permanent: true);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if(result == null)
        {
          FloatingCallBubbleService.to.isVisible.value = true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          final users = ["You", ...controller.userNames.values];

          return Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                "Group Voice Call",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Obx(() {
                switch (controller.callUIState.value) {
                  case CallUIState.calling:
                    return Text(
                      "Calling…",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                    );

                  case CallUIState.connected:
                    return Text(
                      controller.formatDuration(controller.callDuration.value),
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
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: users.length,
                  itemBuilder: (_, i) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        users[i],
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              controller.localUserJoined.value &&
                      (controller.callUIState.value == CallUIState.connected ||
                          controller.callUIState.value == CallUIState.calling)
                  ? _bottomControls(controller)
                  : controller.callUIState.value == CallUIState.timeout
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.white,
                                  child:
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed:() {
                                      // NotificationService().localNotifications.cancel(999);

                                      Get.delete<GroupVoiceCallController>(force: true);
                                      Navigator.pop(context,[false]);
                                    },
                                    color: AppColors.grey,
                                  ),
                                ),
                                const SizedBox(width: 40),
                                CircleAvatar(
                                  backgroundColor: AppColors.white,
                                  child:
                                  IconButton(
                                    icon: Icon(Icons.refresh),
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
              const SizedBox(height: 30),
            ],
          );
        }),
      ),
    );
  }

  Widget _bottomControls(GroupVoiceCallController c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              c.isMuted.value ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
            onPressed: c.toggleMute,
          ),
          IconButton(
            icon: Icon(
              c.isSpeakerOn.value ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: c.toggleSpeaker,
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: c.endCall,
          ),
        ],
      ),
    );
  }
}
