import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:chatify/Screens/status/image_status_preview.dart';
import 'package:chatify/Screens/status/status_page.dart';
import 'package:chatify/Screens/status/text_status_editor_screen.dart';
import 'package:chatify/Screens/status/video_status_editor_screen.dart';
import 'package:chatify/Screens/status/video_status_preview_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/status_controller.dart';
import 'package:chatify/models/status_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';

class StatusScreen extends StatelessWidget {
  StatusScreen({super.key});

  final StatusController controller = Get.put(StatusController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: Get.height * 0.05,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  // mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Status",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      spacing: 10,
                      children: [
                        Container(
                          width: Get.width * 0.1,
                          height: Get.width * 0.1,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade300,
                                  spreadRadius: 1,
                                  blurRadius: 1),
                            ],
                          ),
                          child: Center(
                            child: PopupMenuButton(
                              padding: EdgeInsets.zero,
                              color: AppColors.white,
                              iconColor: AppColors.primary,
                              // iconSize: 26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem(
                                    onTap: () {
                                      Future.delayed(Duration.zero, () {
                                        _showAddStatusBottomSheet(
                                            Get.context!, controller);
                                      });
                                    },
                                    child: Row(
                                      spacing: 6,
                                      children: [
                                        Icon(
                                          Icons.add_box_sharp,
                                          color: AppColors.primary,
                                        ),
                                        Text(
                                          "Add Status",
                                          style:
                                              TextStyle(color: AppColors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  //       PopupMenuItem(
                                  //         onTap: () {
                                  //
                                  //         },
                                  //         child: Row(
                                  //           spacing: 6,
                                  //           children: [
                                  //             Icon(Icons.privacy_tip_outlined,color: AppColors.primary,),
                                  //             Text("Status Privacy",style: TextStyle(color: AppColors.black),),
                                  //           ],
                                  //         ),
                                  //       ),
                                ];
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (controller.myStatuses.isNotEmpty)
                _myStatusTile(controller.myStatuses.first)
              else
                _addStatusTile(),

              if (controller.scheduledStatuses.isNotEmpty) ...[
                const _SectionTitle("Scheduled status"),
                ...controller.scheduledStatuses.map(
                  (status) => _scheduledStatusTile(status),
                ),
              ],

              // if (controller.recentStatuses.isNotEmpty) ...[
              //   const _SectionTitle("Recent status"),
              //   ...controller.recentStatuses.map(_statusTile),
              // ],
              //
              // if (controller.viewedStatuses.isNotEmpty) ...[
              //   const _SectionTitle("Viewed status"),
              //   ...controller.viewedStatuses.map(_statusTile),
              // ],
              Expanded(
                child: Obx(() {
                  final recentUsers = controller.recentStatuses;
                  final viewedUsers = controller.viewedStatuses;

                  final allUsers = [
                    ...recentUsers,
                    ...viewedUsers,
                  ];

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // RECENT UPDATES

                      if (recentUsers.isNotEmpty) ...[
                        const _SectionTitle("Recent updates"),
                        ...List.generate(
                          recentUsers.length,
                          (i) => _statusTile(
                            user: recentUsers[i],
                            allUsers: allUsers,
                            tappedIndex: i, // important
                          ),
                        ),
                      ],

                      // VIEWED UPDATES

                      if (viewedUsers.isNotEmpty) ...[
                        const _SectionTitle("Viewed updates"),
                        ...List.generate(
                          viewedUsers.length,
                          (i) => _statusTile(
                            user: viewedUsers[i],
                            allUsers: allUsers,
                            tappedIndex: recentUsers.length + i, // offset
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ADD STATUS TILE

  Widget _addStatusTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: Get.width * 0.12,
              height: Get.width * 0.12,
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.primary),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  "https://i.pravatar.cc/150?img=10",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -3,
              right: -3,
              child:
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    child: Icon(Icons.add_circle,color: AppColors.black,)),
              // Container(
              //   decoration: BoxDecoration(
              //     color: AppColors.black,
              //     shape: BoxShape.circle,
              //   ),
              //   padding: const EdgeInsets.all(4),
              //   child:
              //   Image.asset(
              //     "assets/images/bottom_status.png",
              //     scale: 4,
              //   ),
              // ),
            ),
          ],
        ),
        title: const Text(
          "Add status",
          // style: TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          "Disappears after 24 hours",
          style: TextStyle(color: Colors.grey),
        ),
        onTap: () {
          _showAddStatusBottomSheet(Get.context!, controller);
        },
      ),
    );
  }

  // STATUS TILE

  Widget _myStatusTile(StatusUser user) {
    final total = user.statuses.length;
    final viewed = user.statuses.where((s) => s.viewed).length;

    return ListTile(
      leading: StatusAvatar(
        image: user.profilePic ?? '',
        total: total,
        viewed: viewed,
      ),
      title: const Text("My status"),
      subtitle: Text(
        "${user.statuses.length} updates",
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_red_eye, size: 18, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            user.statuses.first.viewCount.toString(),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      onTap: () {
        Get.to(() => StatusPage(
              users: [user],
              initialUserIndex: 0,
            ));
      },
    );
  }

  Widget _scheduledStatusTile(ScheduledStatus status) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              // status.mediaUrl,
              networkImg,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: Center(
                child: Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      title: const Text("Scheduled status"),
      subtitle: Text(
        "Will post at ${_formatTime(status.scheduledAt)}",
        style: const TextStyle(color: Colors.grey),
      ),
      trailing:
      PopupMenuButton(
        color: AppColors.white,
        itemBuilder: (_) => [
          PopupMenuItem(
            child: const Text("Delete",style: TextStyle(color: Colors.black),),
            onTap: () async{
              final success =
                  await controller.deleteScheduledStatus(status.id);

              if (success) {
                CustomSnackbar.normal(
                  "Cancelled",
                  "Scheduled status deleted",
                );
              }
            },
          ),
        ],
      ),
      onTap: () {
        _openScheduledStatusPreview(status);
      },
    );
  }

  Widget _statusTile({
    required StatusUser user,
    required List<StatusUser> allUsers,
    required int tappedIndex,
  }) {
    return ListTile(
      leading: StatusAvatar(
        image:
            // user.profilePic,
            networkImg,
        total: user.statuses.length,
        viewed: user.statuses.where((s) => s.viewed).length,
      ),
      title: Text('${user.firstName} ${user.lastName}'),
      subtitle: Text(_formatTime(user.statuses.last.createdAt)),
      onTap: () {
        Get.to(() => StatusPage(
              users: allUsers,
              initialUserIndex: tappedIndex,
            ));
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    final dayDiff = today.difference(date).inDays;

    if (dayDiff == 0) {
      return TimeOfDay.fromDateTime(time).format(Get.context!);
    }

    if (dayDiff == 1) {
      return "Yesterday, ${TimeOfDay.fromDateTime(time).format(Get.context!)}";
    }

    return "${time.day.toString().padLeft(2, '0')}/"
        "${time.month.toString().padLeft(2, '0')}/"
        "${time.year}, "
        "${TimeOfDay.fromDateTime(time).format(Get.context!)}";
  }
}

// SECTION TITLE

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: Get.width * 0.08,
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(70),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(color: AppColors.white),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// STATUS AVATAR WITH SEGMENTS

class StatusAvatar extends StatelessWidget {
  final String image;
  final int total;
  final int viewed;

  const StatusAvatar({
    super.key,
    required this.image,
    required this.total,
    required this.viewed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StatusRingPainter(total, viewed),
      child: CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(
            // image,
            networkImg),
      ),
    );
  }
}

class _StatusRingPainter extends CustomPainter {
  final int total;
  final int viewed;

  _StatusRingPainter(this.total, this.viewed);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final gap = total > 1 ? 0.1 : 0;
    final sweep = (2 * pi - gap * total) / total;

    for (int i = 0; i < total; i++) {
      paint.color = i < viewed ? Colors.grey : AppColors.primary;
      canvas.drawArc(
        rect,
        i * (sweep + gap),
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

void _showAddStatusBottomSheet(
    BuildContext context, StatusController controller) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            _sheetItem(
              icon: Icons.edit,
              color: AppColors.primary,
              title: "Text",
              onTap: () async {
                Get.back();
                final result = await Get.to(() => const TextStatusEditor());
                if (result == true) {
                  controller.loadStatuses();
                }
              },
            ),

            _sheetItem(
              icon: Icons.photo,
              color: Colors.green,
              title: "Gallery Image",
              onTap: () {
                Get.back();
                pickAndEditImage(controller);
              },
            ),

            _sheetItem(
              icon: Icons.videocam,
              color: Colors.red,
              title: "Gallery Video",
              onTap: () {
                Get.back();
                pickAndTrimVideo(controller);
              },
            ),

            _sheetItem(
              icon: Icons.camera_alt,
              color: Colors.orange,
              title: "Camera",
              onTap: () {
                Get.back();
                _captureCameraImage(controller);
              },
            ),
            _sheetItem(
              icon: Icons.schedule,
              color: Colors.blue,
              title: "Add Scheduled Status",
              onTap: () async {
                Get.back();

                final scheduledAt = await _pickScheduleDateTime(context);
                if (scheduledAt == null) return;

                _showScheduledMediaPicker(controller, scheduledAt);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<DateTime?> _pickScheduleDateTime(BuildContext context) async {
  final now = DateTime.now();

  final date = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: now.add(const Duration(days: 30)),
  );

  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (time == null) return null;

  if (date.isBefore(DateTime.now()) && time.isBefore(TimeOfDay.now())) {
    CustomSnackbar.error("Error", "Scheduled time cannot be in the past",);
    return null;
  }
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

void _showScheduledMediaPicker(
  StatusController controller,
  DateTime scheduledAt,
) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetItem(
            icon: Icons.videocam,
            color: Colors.red,
            title: "Text",
            onTap: () async {
              Get.back();
              final result = await Get.to(() => TextStatusEditor(
                    scheduledAt: scheduledAt,
                  ));
              if (result == true) {
                controller.loadScheduledStatuses();
              }
            },
          ),
          _sheetItem(
            icon: Icons.photo,
            color: Colors.green,
            title: "Gallery Image",
            onTap: () {
              Get.back();
              pickScheduledImage(controller, scheduledAt);
            },
          ),
          _sheetItem(
            icon: Icons.videocam,
            color: Colors.red,
            title: "Gallery Video",
            onTap: () {
              Get.back();
              pickScheduledVideo(controller, scheduledAt);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> pickScheduledImage(
  StatusController controller,
  DateTime scheduledAt,
) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 40,
  );

  if (picked == null) return;

  final file = File(picked.path);
  final bytes = await file.readAsBytes();

  final editedBytes = await Get.to<Uint8List?>(
    () => ImageEditor(image: bytes),
  );

  if (editedBytes == null) return;

  final editedFile = File(
    '${file.parent.path}/scheduled_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  await editedFile.writeAsBytes(editedBytes);

  await Get.to(
    () => ImageStatusPreviewScreen(
      file: editedFile,
      controller: controller,
      scheduledAt: scheduledAt, //  ADD THIS
    ),
  );
}

Future<void> pickScheduledVideo(
  StatusController controller,
  DateTime scheduledAt,
) async {
  final picker = ImagePicker();

  final picked = await picker.pickVideo(
    source: ImageSource.gallery,
  );

  if (picked == null) return;

  final trimmedFile = await Get.to<File?>(
    () => VideoStatusEditorScreen(file: File(picked.path)),
  );

  if (trimmedFile == null) return;

  await Get.to(
    () => VideoStatusPreviewScreen(
      file: trimmedFile,
      controller: controller,
      scheduledAt: scheduledAt, //ADD THIS
    ),
  );
}

Future<void> pickAndEditImage(StatusController controller) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 40, // force jpeg conversion if possible
  );

  if (picked == null) return;

  final file = File(picked.path);

  // READ IMAGE AS BYTES (REQUIRED)
  final bytes = await file.readAsBytes();

  // OPEN IMAGE EDITOR (bytes, NOT file)
  final editedBytes = await Get.to<Uint8List?>(
    () => ImageEditor(
      image: bytes,
    ),
  );

  if (editedBytes == null) return;

  // SAVE EDITED IMAGE TO FILE
  final editedFile = File(
    '${file.parent.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  await editedFile.writeAsBytes(editedBytes);

  // OPEN PREVIEW
  await Get.to(() => ImageStatusPreviewScreen(
        file: editedFile,
        controller: controller,
      ));
}

Future<void> pickAndTrimVideo(StatusController controller) async {
  final picker = ImagePicker();
  Get.dialog(
    Center(
        child: CircularProgressIndicator(
      color: Colors.white70,
    )),
    barrierDismissible: false,
  );
  final picked = await picker.pickVideo(
    source: ImageSource.gallery,
    // maxDuration: const Duration(seconds: 60),
  );

  if (picked == null) {
    Get.back();
    return;
  }

  final trimmedFile = await Get.to<File?>(
    () => VideoStatusEditorScreen(file: File(picked.path)),
  );

  Get.back(); // close loader

  if (trimmedFile == null) return;

  await Get.to(
    () => VideoStatusPreviewScreen(
      file: trimmedFile,
      controller: controller,
    ),
  );
}
void _openScheduledStatusPreview(ScheduledStatus status) {
  if (status.type == "IMAGE") {
    Get.to(() => ImageStatusPreviewScreen(
      file: File(status.mediaUrl),
      isScheduledPreview: true,
      controller: null,
      scheduledAt: status.scheduledAt,
    ));
  }
  else if (status.type == "VIDEO") {
    Get.to(() => VideoStatusPreviewScreen(
      file: File(status.mediaUrl),
      controller: null,
      isScheduledPreview: true,
      scheduledAt: status.scheduledAt,
    ));
  }
}


Future<void> _captureCameraImage(StatusController controller) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.camera);

  if (picked == null) return;

  final file = File(picked.path);

  // READ IMAGE AS BYTES (REQUIRED)
  final bytes = await file.readAsBytes();

  // OPEN IMAGE EDITOR (bytes, NOT file)
  final editedBytes = await Get.to<Uint8List?>(
    () => ImageEditor(
      image: bytes,
    ),
  );

  if (editedBytes == null) return;

  // SAVE EDITED IMAGE TO FILE
  final editedFile = File(
    '${file.parent.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  await editedFile.writeAsBytes(editedBytes);

  // OPEN PREVIEW
  await Get.to(() => ImageStatusPreviewScreen(
        file: editedFile,
        controller: controller,
      ));
}

Widget _sheetItem({
  required IconData icon,
  required Color color,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: onTap,
  );
}
