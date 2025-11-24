import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController controller;

  bool showControls = true;
  Timer? hideTimer;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        controller.play();
        startHideTimer();
      });

    controller.addListener(() {
      setState(() {});
    });
  }

  void startHideTimer() {
    hideTimer?.cancel();
    hideTimer = Timer(Duration(seconds: 3), () {
      setState(() => showControls = false);
    });
  }

  void toggleControls() {
    setState(() => showControls = !showControls);
    if (showControls) startHideTimer();
  }

  @override
  void dispose() {
    controller.dispose();
    hideTimer?.cancel();
    super.dispose();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: controller.value.isInitialized
          ? GestureDetector(
        onTap: toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

            /// PLAY / PAUSE BUTTON
            if (showControls)
              GestureDetector(
                onTap: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                  startHideTimer();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),

            /// BACK BUTTON
            if (showControls)
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

            /// PROGRESS BAR + TIME
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Slider(
                    value: controller.value.position.inMilliseconds
                        .toDouble(),
                    max: controller.value.duration.inMilliseconds
                        .toDouble(),
                    onChanged: (v) {
                      controller.seekTo(
                          Duration(milliseconds: v.toInt()));
                    },
                    activeColor: Colors.white,
                    inactiveColor: Colors.white38,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(controller.value.position),
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        formatDuration(controller.value.duration),
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          : Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
