import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/broadcast_controller.dart';

class ScheduledBroadcastsListScreen extends StatelessWidget {
  ScheduledBroadcastsListScreen({super.key});

  final BroadCastController controller =
  Get.put(BroadCastController());
  final themeController = Get.find<ThemeController>();


  @override
  Widget build(BuildContext context) {
    controller.fetchScheduledBroadcasts();

    return Scaffold(
      appBar: AppBar(
        title: Text("Scheduled Broadcasts",style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: themeController.isDarkMode.value
                ? AppColors.white
                : AppColors.black),),
        backgroundColor: themeController.isDarkMode.value
            ? AppColors.black
            : AppColors.white,
      ),
      body: Obx(() {
        if (controller.isFetchingScheduled.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.scheduledBroadcasts.isEmpty) {
          return  Center(
            child: Text("No scheduled broadcasts",style: TextStyle(
                color: themeController.isDarkMode.value
                    ? AppColors.white
                    : AppColors.black),),
          );
        }

        return ListView.separated(
          itemCount: controller.scheduledBroadcasts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = controller.scheduledBroadcasts[index];
            final type = item['type'];
            final content = item['content'];
            final scheduledAt = item['scheduledAt'];
            final totalRecipients = item['totalRecipients'];
            return ListTile(
              leading: _typeIcon(type),
              title: Text(
                content ?? "Media Broadcast",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Scheduled: ${_formatDate(scheduledAt)}\n"
                    "Recipients: $totalRecipients",
              ),
              isThreeLine: true,
              trailing: PopupMenuButton(
                color: AppColors.white,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    child: const Text("Delete",style: TextStyle(color: Colors.black),),
                    onTap: () async{
                      final success =
                      await controller.deleteScheduledBroadcast(item['id']);

                      if (success) {
                        Get.snackbar("Deleted", "Scheduled broadcast deleted");
                      }

                    },
                  ),
                ],
              ),
            );

          },
        );
      }),
    );
  }

  /// ---------------- Helpers ----------------

  Icon _typeIcon(String type) {
    switch (type) {
      case "IMAGE":
        return const Icon(Icons.image);
      case "VIDEO":
        return const Icon(Icons.videocam);
      case "VOICE":
        return const Icon(Icons.mic);
      default:
        return const Icon(Icons.text_snippet);
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.day}/${dt.month}/${dt.year} • "
        "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
