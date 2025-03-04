import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundSettingsProvider with ChangeNotifier {
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  SoundSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool("isMuted") ?? false; // Default is sound ON
    notifyListeners();
  }

  Future<void> toggleMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isMuted", value);
    _isMuted = value;
    notifyListeners();
  }
}
