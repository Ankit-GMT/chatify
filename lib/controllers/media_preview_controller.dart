import 'dart:io';
import 'package:chatify/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class MediaPreviewController extends GetxController {
  final String filePath;
  final String type;

  MediaPreviewController(this.filePath, this.type);

  RxString caption = "".obs;
  // IMAGE
  Rx<File> imageFile = File("").obs;

  void setImage(String path) {
    imageFile.value = File(path);
  }

  Future<void> cropImage() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.value.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppColors.black,
          toolbarWidgetColor: AppColors.white,
          activeControlsWidgetColor: AppColors.primary,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (cropped != null) {
      imageFile.value = File(cropped.path);
    }
  }

  // VIDEO
  VideoPlayerController? videoController;
  var videoInitialized = false.obs;

  // AUDIO
  final audioPlayer = AudioPlayer();
  var isPlayingAudio = false.obs;
  var audioDuration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();

    if (type == "VIDEO") {
      videoController = VideoPlayerController.file(File(filePath))
        ..initialize().then((_) {
          videoInitialized.value = true;
        });
    }

    if (type == "AUDIO") {
      _initAudio();
    }
  }

  Future<void> _initAudio() async {
    await audioPlayer.setFilePath(filePath);
    audioDuration.value = audioPlayer.duration ?? Duration.zero;

    audioPlayer.playerStateStream.listen((state) {
      isPlayingAudio.value = state.playing;
    });
  }

  Future<void> toggleAudio() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play();
    }
  }

  @override
  void onClose() {
    videoController?.dispose();
    audioPlayer.dispose();
    super.onClose();
  }
}
