import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerController extends GetxController {
  final player = AudioPlayer();

  Rx<Duration> current = Duration.zero.obs;
  Rx<Duration> total = Duration.zero.obs;
  Rx<bool> isPlaying = false.obs;

  Future<void> init(String url) async {
    try {
      await player.setUrl(url);

      total.value = player.duration ?? Duration.zero;

      player.positionStream.listen((pos) {
        current.value = pos;
      });

      player.playerStateStream.listen((state) {
        isPlaying.value = state.playing;

        // auto stop at the end
        if (state.processingState == ProcessingState.completed) {
          player.seek(Duration.zero);
          player.pause();
        }
      });
    } catch (e) {
      print("Audio Load Error: $e");
    }
  }

  void play() => player.play();
  void pause() => player.pause();

  void toggle() {
    if (player.playing) {
      pause();
    } else {
      play();
    }
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }
}
