import 'package:audioplayers/audioplayers.dart';
import 'package:card_battle_game/providers/sound_settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class SoundPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isMuted(BuildContext context) {
    return Provider.of<SoundSettingsProvider>(context, listen: false).isMuted;
  }

  Future<void> playSound(BuildContext context, String sound) async {
    if (!isMuted(context)) {
      await _audioPlayer.play(AssetSource('sounds/$sound'));
    }
  }
}

class Sounds {
  static String dropCard = 'drop_card.mp3';
}
