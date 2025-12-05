import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/assets.dart';
import '../../models/user_model.dart';
import '../../widgets/game_card.dart';
import '../../widgets/social_media_card.dart';
import '../../services/music_service.dart';
import '../games/number_puzzle_page.dart';
import '../games/car_game_page.dart';
import '../games/memory_game_page.dart';
import '../games/snake_game_page.dart';
import '../games/recycling_game_page.dart';
import '../games/eco_quiz_page.dart';
import '../chat/chat_page.dart';
import '../auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamesMenuPage extends StatefulWidget {
  final UserModel user;

  const GamesMenuPage({super.key, required this.user});

  @override
  State<GamesMenuPage> createState() => _GamesMenuPageState();
}

class _GamesMenuPageState extends State<GamesMenuPage> {
  bool _isMusicOn = MusicService.instance.isMusicEnabled;

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userId');

              if (!context.mounted) return;

              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showMusicSettings() {
    double volume = MusicService.instance.volume;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                    setDialogState(() {
                      _isMusicOn = value;
                    });
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
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(volume * 100).round()}%',
                        onChanged: _isMusicOn
                            ? (value) {
                          setDialogState(() {
                            volume = value;
                          });
                          MusicService.instance.setVolume(value);
                        }
                            : null,
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),
                Text(
                  'Volume: ${(volume * 100).round()}%',
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.games, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Bonjour, ${widget.user.name}'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Musique
          IconButton(
            icon: Icon(
              _isMusicOn ? Icons.music_note : Icons.music_off,
              color: _isMusicOn ? Colors.amber : Colors.grey,
            ),
            onPressed: () async {
              await MusicService.instance.toggleMusic();
              setState(() {
                _isMusicOn = MusicService.instance.isMusicEnabled;
              });

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isMusicOn ? '🎵 Musique activée' : '🔇 Musique désactivée',
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: _isMusicOn ? Colors.green : Colors.grey,
                ),
              );
            },
            tooltip: 'Musique',
          ),

          // Profil
          IconButton(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                widget.user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profil'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nom: ${widget.user.name}'),
                      Text('Email: ${widget.user.email}'),
                      const Divider(),
                      const Text(
                        'Meilleurs scores:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildScoreRow('Puzzle', widget.user.puzzleScore),
                      _buildScoreRow('Course', widget.user.carGameScore),
                      _buildScoreRow('Mémoire', widget.user.memoryGameScore),
                      _buildScoreRow('Snake', widget.user.snakeGameScore),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppStrings.logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fond complet du menu
          Positioned.fill(
            child: Image.asset(
              AppAssets.background, // image dédiée au menu
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.backgroundGradient,
                  ),
                );
              },
            ),
          ),

          // Voile sombre
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Contenu
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.chooseGame,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez un jeu pour commencer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Puzzle
                  GameCard(
                    title: AppStrings.puzzle,
                    subtitle: 'Ordonnez les chiffres',
                    icon: Icons.view_compact,
                    color: AppColors.puzzleColor,
                    bestScore: widget.user.puzzleScore,
                    imageAsset: AppAssets.puzzleBg,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NumberPuzzlePage(user: widget.user),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Course
                  GameCard(
                    title: AppStrings.carGame,
                    subtitle: 'Évitez les obstacles',
                    icon: Icons.directions_car,
                    color: AppColors.carGameColor,
                    bestScore: widget.user.carGameScore,
                    imageAsset: AppAssets.voitureIcon,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CarGamePage(user: widget.user),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Mémoire
                  GameCard(
                    title: AppStrings.memoryGame,
                    subtitle: 'Trouvez les paires',
                    icon: Icons.psychology,
                    color: AppColors.memoryGameColor,
                    bestScore: widget.user.memoryGameScore,
                    imageAsset: AppAssets.memoryBg,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MemoryGamePage(user: widget.user),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Snake
                  GameCard(
                    title: AppStrings.snakeGame,
                    subtitle: 'Mangez et grandissez',
                    icon: Icons.grid_4x4,
                    color: AppColors.snakeGameColor,
                    bestScore: widget.user.snakeGameScore,
                    imageAsset: AppAssets.snakeBg,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SnakeGamePage(user: widget.user),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tri des déchets
                  GameCard(
                    title: 'Tri des déchets',
                    subtitle: 'Classez les déchets dans le bon bac',
                    icon: Icons.recycling,
                    color: Colors.greenAccent,
                    bestScore: 0,
                    imageAsset: AppAssets.memoryBg,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecyclingGamePage(),
                        ),
                      );
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quiz écologie
                  GameCard(
                    title: 'اختبار البيئة',
                    subtitle: 'أسئلة صح أو خطأ عن حماية الطبيعة',
                    icon: Icons.quiz,
                    color: Colors.tealAccent,
                    bestScore: 0,
                    imageAsset: AppAssets.sudokuBg,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EcoQuizPage(),
                        ),
                      );
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 50),
                  const Divider(color: Colors.white24, thickness: 2),
                  const SizedBox(height: 25),

                  const Icon(
                    Icons.movie,
                    size: 45,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🎥 Vidéos Nature & Environnement',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Regardez des vidéos éducatives sur la planète',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 25),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: const [
                      SocialMediaCard(
                        name: 'Protéger les océans',
                        icon: Icons.play_circle_fill,
                        color: Color(0xFF2196F3),
                        url: 'https://www.youtube.com/watch?v=jlRE6JeGGp8',
                      ),
                      SocialMediaCard(
                        name: 'Recyclage des déchets',
                        icon: Icons.play_circle_fill,
                        color: Color(0xFF4CAF50),
                        url: 'https://www.youtube.com/watch?v=-MCf7WQiNLc',
                      ),
                      SocialMediaCard(
                        name: 'Forêts et climat',
                        icon: Icons.play_circle_fill,
                        color: Color(0xFFFF9800),
                        url: 'https://www.youtube.com/watch?v=F0pUIELJxa0',
                      ),
                      SocialMediaCard(
                        name: 'Économie d\'eau',
                        icon: Icons.play_circle_fill,
                        color: Color(0xFF9C27B0),
                        url: 'https://www.youtube.com/watch?v=YzgQXpgsdww',
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),
                  const Divider(color: Colors.white24, thickness: 2),
                  const SizedBox(height: 25),

                  const Icon(
                    Icons.chat_bubble,
                    size: 45,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💬 Assistant Virtuel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Posez vos questions à notre IA',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10A37F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy, size: 32),
                          SizedBox(width: 15),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ouvrir le Chat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Assistant IA disponible 24/7',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _showMusicSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Paramètres Audio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String game, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(game),
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
