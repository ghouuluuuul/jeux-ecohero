import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicService {
  static final MusicService instance = MusicService._init();
  MusicService._init();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicEnabled = true;
  bool _isPlaying = false;
  double _volume = 0.5;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('musicEnabled') ?? true;
    _volume = prefs.getDouble('musicVolume') ?? 0.5;

    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(_volume);

    if (_isMusicEnabled) {
      await playMusic();
    }
  }

  Future<void> playMusic() async {
    if (!_isMusicEnabled || _isPlaying) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/background_music.mp3'));
      _isPlaying = true;
    } catch (e) {
      print('Erreur lecture musique: $e');
    }
  }

  Future<void> pauseMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  Future<void> stopMusic() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _isMusicEnabled);

    if (_isMusicEnabled) {
      await playMusic();
    } else {
      await pauseMusic();
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', _volume);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
