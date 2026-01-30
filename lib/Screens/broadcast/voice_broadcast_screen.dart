import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/broadcast_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VoiceBroadcastScreen extends StatelessWidget {
  VoiceBroadcastScreen({super.key});

  final BroadCastController controller = Get.put(BroadCastController());

  final tabController = Get.find<TabBarController>();
  final themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;

    if (args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setVoiceRecording(
          args["path"],
          args["duration"],
        );
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeController.isDarkMode.value
            ? AppColors.black
            : AppColors.white,
        title: Obx(() => Text(
              controller.selectedUserIds.isEmpty
                  ? "Voice Broadcast"
                  : "${controller.selectedUserIds.length} selected",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode.value
                      ? AppColors.white
                      : AppColors.black),
            )),
        actions: [
          Obx(() => IconButton(
                icon: controller.isLoading.value
                    ? const CircularProgressIndicator(
                        color: AppColors.primary,
                      )
                    : Icon(
                        Icons.send,
                        color: AppColors.primary,
                      ),
                onPressed: controller.recordedFilePath.isEmpty ||
                        controller.selectedUserIds.isEmpty
                    ? null
                    : () {
                        if (controller.isScheduled.value) {
                          if (controller.scheduledAt.value == null) {
                            CustomSnackbar.error("Error", "Select date & time");
                            return;
                          }

                          controller.sendScheduledVoiceBroadcast(
                              filePath: controller.recordedFilePath.value,
                              recipientIds: controller.selectedUserIds.toList(),
                              scheduledAt: controller.scheduledAt.value!,
                              duration: controller.recordedDuration.value);
                        } else {
                          controller.sendVoiceBroadcast(
                            filePath: controller.recordedFilePath.value,
                            recipientIds: controller.selectedUserIds.toList(),
                            duration: controller.recordedDuration.value,
                          );
                        }
                      },
              )),
        ],
      ),
      body: Column(
        children: [
          /// Voice Preview
          Obx(() => Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: controller.recordedFilePath.isEmpty
                    ? Text(
                        "No voice recorded",
                        style: TextStyle(
                            color: AppColors.black),
                      )
                    : Row(
                        children: [
                           Icon(Icons.mic,color: AppColors.black,),
                          const SizedBox(width: 10),
                          Text(
                            "Voice message • ${controller.recordedDuration}s",
                            style: TextStyle(
                                color: AppColors.black),
                          ),
                        ],
                      ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(
              () => Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 8),
                  const Text("Schedule"),
                  const Spacer(),
                  Switch(
                    value: controller.isScheduled.value,
                    onChanged: (value) async {
                      controller.isScheduled.value = value;

                      if (value) {
                        final now = DateTime.now();

                        final date = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                        );

                        if (date == null) {
                          controller.isScheduled.value = false;
                          return;
                        }

                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (time == null) {
                          controller.isScheduled.value = false;
                          return;
                        }

                        controller.scheduledAt.value = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      } else {
                        controller.scheduledAt.value = null;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (!controller.isScheduled.value ||
                controller.scheduledAt.value == null) {
              return const SizedBox();
            }

            final dt = controller.scheduledAt.value!;
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                "Scheduled for: ${dt.toIso8601String()}",
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }),

          const Divider(),

          /// Select Users
          Expanded(
            child: ListView.builder(
              itemCount: tabController.registeredUsers.length,
              itemBuilder: (_, index) {
                final contact = tabController.registeredUsers[index];

                return Obx(() {
                  final isSelected =
                      controller.selectedUserIds.contains(contact.userId!);
                  return ListTile(
                    onTap: () => controller.toggleUser(contact.userId!),
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(contact.profileImageUrl ?? ''),
                    ),
                    title: Text("${contact.firstName} ${contact.lastName}"),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.radio_button_unchecked,
                            color: Colors.grey),
                    tileColor:
                        isSelected ? Colors.green.withOpacity(0.1) : null,
                  );
                });
              },
            ),
          ),
        ],
      ),

      /// Record Button
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.mic),
      //   onPressed: () async {
      //     /// Navigate to your existing voice recorder
      //     /// After recording:
      //     /// Get.back(result: {"path": filePath, "duration": seconds});
      //
      //     final result = await Get.to(() => const VoiceRecorderScreen());
      //
      //     if (result != null) {
      //       controller.setVoiceRecording(
      //         result["path"],
      //         result["duration"],
      //       );
      //     }
      //   },
      // ),
    );
  }
}
