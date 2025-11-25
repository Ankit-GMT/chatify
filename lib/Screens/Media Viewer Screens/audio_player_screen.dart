import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/audio_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

void openAudioPlayerSheet(BuildContext context, String audioUrl, String fileName) {
  final controller = Get.put(AudioPlayerController());

  controller.init(audioUrl);

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Container(
        padding: EdgeInsets.all(Get.width * 0.05),
        height: Get.height *0.24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                SizedBox(
                  width: Get.width * 0.7,
                  child: Text(
                    fileName,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white
                    ),
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close,color: AppColors.white,),
                  onPressed: () {
                    controller.player.stop();
                    Get.delete<AudioPlayerController>();
                    Get.back();
                  },
                )
              ],
            ),
            const SizedBox(height: 20),

            // Wave/Seek Bar using audio_video_progress_bar
            Obx(() {
              return ProgressBar(
                progress: controller.current.value,
                total: controller.total.value,
                onSeek: controller.player.seek,
                barHeight: 5,
                baseBarColor: Colors.grey.shade300,
                progressBarColor: Colors.white,
                thumbColor: Colors.white,
              );
            }),

             SizedBox(height: Get.height * 0.02),

            // Play / Pause Button
            Center(
              child: Obx(() {
                return InkWell(
                  onTap: controller.toggle,
                  child: CircleAvatar(
                    radius: Get.height * 0.03 ,
                    backgroundColor: AppColors.white,
                    child: Icon(
                      controller.isPlaying.value
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: Get.height * 0.04,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    },
  );
}
