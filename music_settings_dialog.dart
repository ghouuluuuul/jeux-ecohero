import 'package:flutter/material.dart';
import '../services/music_service.dart';

class MusicSettingsDialog extends StatefulWidget {
  const MusicSettingsDialog({super.key});

  @override
  State<MusicSettingsDialog> createState() => _MusicSettingsDialogState();
}

class _MusicSettingsDialogState extends State<MusicSettingsDialog> {
  double _volume = MusicService.instance.volume;
  bool _isMusicOn = MusicService.instance.isMusicEnabled;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.music_note, color: Colors.amber),
          SizedBox(width: 10),
          Text('Paramètres Audio'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Musique de fond'),
            subtitle: Text(_isMusicOn ? 'Activée' : 'Désactivée'),
            value: _isMusicOn,
            activeColor: Colors.green,
            onChanged: (value) async {
              await MusicService.instance.toggleMusic();
              setState(() {
                _isMusicOn = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.volume_down),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_volume * 100).round()}%',
                  onChanged: _isMusicOn ? (value) {
                    setState(() {
                      _volume = value;
                    });
                    MusicService.instance.setVolume(value);
                  } : null,
                ),
              ),
              const Icon(Icons.volume_up),
            ],
          ),
          Text(
            'Volume: ${(_volume * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
