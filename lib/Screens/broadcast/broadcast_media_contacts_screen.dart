import 'dart:io';

import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/broadcast_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaBroadcastContactsScreen extends StatelessWidget {
  MediaBroadcastContactsScreen({super.key});

  final controller = Get.put(BroadCastController());
  final tabController = Get.find<TabBarController>();

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final File file = args["file"];
    final String type = args["type"];
    final String caption = args["caption"];

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.selectedUserIds.isEmpty
                  ? "Select Recipients"
                  : "${controller.selectedUserIds.length} selected",
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
                onPressed: controller.selectedUserIds.isEmpty
                    ? null
                    : () {
                        if (controller.isScheduled.value) {
                          if (controller.scheduledAt.value == null) {
                            CustomSnackbar.error("Error", "Select date & time");
                            return;
                          }

                          controller.sendScheduledMediaBroadcast(
                            filePath: file.path,
                            type: type,
                            caption: caption,
                            recipientIds: controller.selectedUserIds.toList(),
                            scheduledAt: controller.scheduledAt.value!,
                          );
                        } else {
                          controller.sendMediaBroadcast(
                            filePath: file.path,
                            type: type,
                            caption: caption,
                            recipientIds: controller.selectedUserIds.toList(),
                          );
                        }
                      },
              )),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: ListView.builder(
              itemCount: tabController.registeredUsers.length,
              itemBuilder: (_, index) {
                final user = tabController.registeredUsers[index];
                return Obx(
                  () {
                    final isSelected =
                        controller.selectedUserIds.contains(user.userId!);
                    return ListTile(
                      onTap: () => controller.toggleUser(user.userId!),
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(user.profileImageUrl ?? ""),
                      ),
                      title: Text("${user.firstName} ${user.lastName}"),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
