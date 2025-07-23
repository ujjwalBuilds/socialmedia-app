

import 'package:shared_preferences/shared_preferences.dart';

class VoiceSettings {
  static const String _voiceKey = 'selected_voice';
  static const String _defaultVoice = 'male';

  static Future<String> getSelectedVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_voiceKey) ?? _defaultVoice;
  }

  static Future<void> setSelectedVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKey, voice);
  }

  static String getVoiceName(String voice) {
    switch (voice) {
      case 'male':
        return 'Michael';
      case 'female':
        return 'Vanessa';
      default:
        return 'Michael';
    }
  }
}