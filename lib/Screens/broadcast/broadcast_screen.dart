import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/broadcast_controller.dart';

class BroadcastScreen extends StatelessWidget {
  BroadcastScreen({super.key});

  final BroadCastController controller = Get.put(BroadCastController());

  final tabController = Get.find<TabBarController>();
  final themeController = Get.find<ThemeController>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeController.isDarkMode.value
            ? AppColors.black
            : AppColors.white,
        title: Obx(() => Text(
              controller.selectedUserIds.isEmpty
                  ? "New Broadcast"
                  : "${controller.selectedUserIds.length} selected",style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: themeController.isDarkMode.value
                ? AppColors.white
                : AppColors.black),
            )),
        actions: [
          Obx(() => IconButton(
                icon: controller.isLoading.value
                    ? const CircularProgressIndicator(color: AppColors.primary,)
                    : Icon(
                        Icons.send,
                        color: AppColors.primary,
                      ),
                onPressed: controller.selectedUserIds.isEmpty
                    ? null
                    : () {
                        final message =
                            controller.messageController.text.trim();

                        if (message.isEmpty) {
                          CustomSnackbar.error("Error", "Message cannot be empty");
                          return;
                        }

                        if (controller.isScheduled.value) {
                          if (controller.scheduledAt.value == null) {
                            CustomSnackbar.error("Error", "Select date & time");
                            return;
                          }

                          controller.sendScheduledBroadcast(
                            content: message,
                            recipientIds: controller.selectedUserIds.toList(),
                            scheduledAt: controller.scheduledAt.value!,
                          );
                        } else {
                          controller.sendBroadcastMessage(
                            content: message,
                            recipientIds: controller.selectedUserIds.toList(),
                          );
                        }
                      },
              )),
        ],
      ),
      body: Column(
        children: [
          /// Message Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller.messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Type broadcast message...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
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

          /// Contact List
          Expanded(
            child: ListView.builder(
              itemCount: tabController.registeredUsers.length,
              itemBuilder: (context, index) {
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
    );
  }
}
