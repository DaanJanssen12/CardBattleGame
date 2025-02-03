import 'package:audioplayers/audioplayers.dart';

class SoundPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playDropSound() async {
    await _audioPlayer.play(AssetSource('sounds/drop_card.mp3'));
  }
}
