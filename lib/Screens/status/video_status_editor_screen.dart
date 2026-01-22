import 'dart:io';
import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoStatusEditorScreen extends StatefulWidget {
  final File file;
  const VideoStatusEditorScreen({super.key, required this.file});

  @override
  State<VideoStatusEditorScreen> createState() => _VideoStatusEditorScreenState();
}

class _VideoStatusEditorScreenState extends State<VideoStatusEditorScreen> {
  late VideoEditorController _controller;
  bool _isExporting = false;
  final Trimmer _trimmer = Trimmer();

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.file,
      minDuration: const Duration(seconds: 2),
      maxDuration: const Duration(seconds: 60),
    )..initialize().then((_) => setState(() {}));

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The FFmpeg logic to cut the video physically
  // Future<String?> _trimWithFFmpeg() async {
  //   final Directory tempDir = await getTemporaryDirectory();
  //   final String outputPath =
  //       "${tempDir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4";
  //
  //   // Convert Duration to FFmpeg timestamp format (00:00:00.000)
  //   String formatDuration(Duration d) {
  //     String twoDigits(int n) => n.toString().padLeft(2, "0");
  //     String threeDigits(int n) => n.toString().padLeft(3, "0");
  //     return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}.${threeDigits(d.inMilliseconds.remainder(1000))}";
  //   }
  //
  //   final start = formatDuration(_controller.startTrim);
  //   final duration = formatDuration(_controller.trimmedDuration);
  //
  //   // FFmpeg command: -ss (start), -t (duration), -c copy (fastest, no re-encoding)
  //   final command = "-ss $start -i \"${widget.file.path}\" -t $duration -c copy \"$outputPath\"";
  //
  //   final session = await FFmpegKit.execute(command);
  //   final returnCode = await session.getReturnCode();
  //
  //   if (ReturnCode.isSuccess(returnCode)) {
  //     return outputPath;
  //   } else {
  //     debugPrint("FFmpeg Error: ${await session.getLogsAsString()}");
  //     return null;
  //   }
  // }
  Future<String?> _saveVideoNative() async {
    await _trimmer.loadVideo(videoFile: widget.file);

    final videoDurationMs = _controller.maxDuration.inMilliseconds.toDouble();

    double safeStart = _controller.startTrim.inMilliseconds.toDouble();
    double safeEnd = _controller.endTrim.inMilliseconds.toDouble();

    // IMPORTANT FIX: Ensure end value is always within bounds
    if (safeEnd > videoDurationMs) {
      safeEnd = videoDurationMs;
    }

    String? outputPath;

    await _trimmer.saveTrimmedVideo(
      startValue: safeStart,
      endValue: safeEnd,
      onSave: (String? path) {
        outputPath = path;
      },
    );

    return outputPath;
  }


  Future<void> _saveVideo() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    // Call the native trimmer
    final  output = await _saveVideoNative();

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (output != null) {
      Navigator.pop(context, File(output));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to trim video")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: Text(_isExporting ? "Trimming..." : "Trim Video"),
        actions: [
          _isExporting
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
            onPressed: _saveVideo,
            icon:  Icon(Icons.check, color: AppColors.primary),
          )
        ],
      ),
      body: _controller.initialized
          ? Column(
        children: [
          Expanded(child: CropGridViewer.preview(controller: _controller)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: _controller.video,
                  builder: (_, video, __) {
                    return Text("Selection: ${_controller.endTrim.inSeconds-_controller.startTrim.inSeconds}s",
                        style: const TextStyle(color: Colors.white));
                  }
                ),
                const SizedBox(height: 10),
                TrimSlider(
                  controller: _controller,
                  height: 60,
                  child: TrimTimeline(controller: _controller,),
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _controller.video,
            builder: (context, value, child) {
              return IconButton(
                onPressed:_isExporting
                    ? null
                    : () => _controller.video.value.isPlaying
                    ? _controller.video.pause()
                    : _controller.video.play(),
                icon: Icon(
                  _controller.video.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              );
            }
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

