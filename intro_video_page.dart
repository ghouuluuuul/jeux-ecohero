import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // rootBundle
import 'package:path_provider/path_provider.dart';
import 'package:video_player_win/video_player_win.dart';

class IntroVideoPage extends StatefulWidget {
  final Widget nextPage;

  const IntroVideoPage({super.key, required this.nextPage});

  @override
  State<IntroVideoPage> createState() => _IntroVideoPageState();
}

class _IntroVideoPageState extends State<IntroVideoPage> {
  WinVideoPlayerController? _controller;
  bool _isReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAndPlayVideo();
  }

  Future<void> _loadAndPlayVideo() async {
    try {
      // 1. Charger la vidéo depuis les assets
      final bytes = await rootBundle.load('assets/videos/intro.mp4');

      // 2. L’écrire dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/intro_temp.mp4');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(),
        flush: true,
      );

      // 3. Créer le contrôleur vidéo WinVideoPlayer
      final controller = WinVideoPlayerController.file(file);

      await controller.initialize();

      if (!mounted) return;

      controller.play();
      controller.setLooping(false);
      controller.addListener(_checkVideoEnd);

      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur de lecture vidéo: $e';
      });
    }
  }

  void _checkVideoEnd() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;

    // Utilise isCompleted fourni par video_player_win
    if (value.isCompleted) {
      _goNext();
    }
  }

  void _goNext() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_checkVideoEnd);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextPage),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkVideoEnd);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isReady && _controller != null
            ? AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: WinVideoPlayer(_controller!),
        )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
