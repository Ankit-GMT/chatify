import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/call_history_controller.dart';
import '../controllers/message_controller.dart';
import '../models/call_history.dart';

class VideoCallHistoryScreen extends StatelessWidget {
  VideoCallHistoryScreen({
    super.key,
  });

  final callHistoryController = Get.put(CallHistoryController());
  final profileController = Get.find<ProfileController>();
  final messageController = Get.put(MessageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Calls"),
      ),
      body: Obx(() {
        if (callHistoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (callHistoryController.videoCallHistoryList.isEmpty) {
          return const Center(
            child: Text("No call history found"),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!callHistoryController.isMoreLoading.value &&
                scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
              callHistoryController.loadMore("voice");
            }
            return true;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 70),
              itemCount: callHistoryController.videoCallHistoryList.length +
                  (callHistoryController.isMoreLoading.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index ==
                    callHistoryController.videoCallHistoryList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final CallHistory call =
                    callHistoryController.videoCallHistoryList[index];
                final name = call.caller.id == profileController.user.value?.id
                    ? "${call.receiver?.firstName} ${call.receiver?.lastName}"
                    : "${call.caller.firstName} ${call.caller.lastName}";

                return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(call.caller.profileImageUrl!),
                    ),
                    title: Text(
                      // '${call.receiver?.firstName} ${call.receiver?.lastName}',
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      spacing: 5,
                      children: [
                        Icon(
                          call.caller.id == profileController.user.value?.id
                              ? Icons.call_received
                              : Icons.call_made,
                          color:
                              call.caller.id == profileController.user.value?.id
                                  ? Colors.green
                                  : Colors.red,
                          size: 15,
                        ),
                        Text(
                          "${call.createdAt.day}/${call.createdAt.month}/${call.createdAt.year} ${call.createdAt.hour}:${call.createdAt.minute}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        final myId = profileController.user.value?.id;
                        final receiverId = call.caller.id == myId
                            ? call.receiver?.id
                            : call.caller.id;
                        call.callType == "VIDEO"
                            ? messageController.startCall(
                                name,
                                receiverId.toString(),
                                call.channelId,
                                true,
                                context)
                            : messageController.startGroupCall(
                                context: context,
                                channelId: call.channelId,
                                callerId: myId.toString(),
                                callerName:
                                    profileController.user.value!.firstName!,
                                isVideo: true,
                                receiverIds: call.participants!
                                    .map((e) => e.id.toString())
                                    .where((id) => id != myId.toString())
                                    .toList());
                      },
                      icon: Icon(
                        call.callType == "VIDEO" ? Icons.videocam : Icons.group,
                        color: AppColors.primary,
                      ),
                    ));
              },
            ),
          ),
        );
      }),
    );
  }
}
