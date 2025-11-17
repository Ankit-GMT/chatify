import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/call_history_controller.dart';
import '../models/call_history.dart';


class VoiceCallHistoryScreen extends StatelessWidget {

  VoiceCallHistoryScreen({super.key,});

  final callHistoryController = Get.put(CallHistoryController());

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Calls"),
      ),
      body: Obx(() {
        if (callHistoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (callHistoryController.voiceCallHistoryList.isEmpty) {
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
            padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 70),
              itemCount: callHistoryController.voiceCallHistoryList.length +
                  (callHistoryController.isMoreLoading.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == callHistoryController.voiceCallHistoryList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final CallHistory call = callHistoryController.voiceCallHistoryList[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(call.caller.profileImageUrl!),
                  ),
                  title: Text(
                    '${call.receiver?.firstName} ${call.receiver?.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${call.createdAt.day}/${call.createdAt.month}/${call.createdAt.year} ${call.createdAt.hour}:${call.createdAt.minute}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                call.callType == "VOICE"
                ? Icons.call
                    : call.callType == "VIDEO"
                ? Icons.videocam
                    : Icons.group,
                color: AppColors.primary,
                ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
