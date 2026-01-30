import 'dart:async';
import 'dart:io';

import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';


class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {

  final AudioRecorder _record = AudioRecorder();
  final themeController = Get.find<ThemeController>();

  bool _isRecording = false;
  int _duration = 0;
  Timer? _timer;
  String? _filePath;

  @override
  void dispose() {
    _timer?.cancel();
    _record.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _record.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path =
          "${dir.path}/broadcast_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _record.start(
        RecordConfig(
          encoder: AudioEncoder.aacEld,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _filePath = path;
      _duration = 0;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _duration++);
      });

      setState(() => _isRecording = true);
    } else {
      CustomSnackbar.error("Permission denied", "Microphone access is required");
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _record.stop();

    setState(() => _isRecording = false);

    if (_filePath != null && File(_filePath!).existsSync()) {
      Get.back(
        result: {
          "path": _filePath!,
          "duration": _duration,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record Voice",style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600,color: themeController.isDarkMode.value ? AppColors.white: AppColors.black),),
        backgroundColor:themeController.isDarkMode.value ? AppColors.black: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 80,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 20),

            Text(
              _isRecording
                  ? "Recording... $_duration s"
                  : "Hold button to record",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.green,
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
