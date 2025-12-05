import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/assets.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class CarGamePage extends StatefulWidget {
  final UserModel user;
  const CarGamePage({super.key, required this.user});

  @override
  State<CarGamePage> createState() => _CarGamePageState();
}

class _CarGamePageState extends State<CarGamePage> {
  int playerLane = 1;
  List<Obstacle> obstacles = [];
  int score = 0;
  bool isGameOver = false;
  bool isGameStarted = false;

  Timer? gameTimer;
  Timer? obstacleTimer;

  final FocusNode _focusNode = FocusNode();
  final Random random = Random();

  @override
  void dispose() {
    gameTimer?.cancel();
    obstacleTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- LOGIQUE JEU ----------------

  void startGame() {
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      score = 0;
      obstacles.clear();
      playerLane = 1;
    });

    // boucle plus lente
    gameTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!isGameOver && isGameStarted) {
        updateGame();
      }
    });

    // obstacles moins fréquents
    obstacleTimer =
        Timer.periodic(const Duration(milliseconds: 1100), (timer) {
          if (!isGameOver && isGameStarted) {
            addObstacle();
          }
        });
  }

  void updateGame() {
    setState(() {
      // descente plus lente
      for (var obstacle in obstacles) {
        obstacle.y += 0.015;
      }

      obstacles.removeWhere((obstacle) => obstacle.y > 1.2);

      // collisions
      for (var obstacle in List<Obstacle>.from(obstacles)) {
        if (obstacle.lane == playerLane &&
            obstacle.y > 0.78 &&
            obstacle.y < 0.86) {
          if (obstacle.isGood) {
            score += 10;
            obstacles.remove(obstacle);
          } else {
            gameOver();
            break;
          }
        }
      }
    });
  }

  void addObstacle() {
    setState(() {
      bool isGood = random.nextBool(); // vrai ou faux
      int typeIndex = random.nextInt(4); // 0..3

      obstacles.add(Obstacle(
        lane: random.nextInt(4),
        y: -0.2,
        isGood: isGood,
        typeIndex: typeIndex,
      ));
    });
  }

  void moveLeft() {
    if (!isGameOver && playerLane > 0) {
      setState(() => playerLane--);
    }
  }

  void moveRight() {
    if (!isGameOver && playerLane < 3) {
      setState(() => playerLane++);
    }
  }

  Future<void> gameOver() async {
    setState(() => isGameOver = true);
    gameTimer?.cancel();
    obstacleTimer?.cancel();

    await DatabaseService.instance.updateScore(
      userId: widget.user.id!,
      gameType: 'carGame',
      score: score,
    );

    if (score > widget.user.carGameScore) {
      widget.user.carGameScore = score;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Fin de partie',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied,
                size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Pacman a mangé une poubelle…',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.carGameColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.carGameColor,
                    ),
                  ),
                  if (score > widget.user.carGameScore) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Nouveau record !',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: const Text(
              AppStrings.replay,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text(
              AppStrings.menu,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        moveLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        moveRight();
      } else if (event.logicalKey == LogicalKeyboardKey.space &&
          !isGameStarted) {
        startGame();
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pacman Écolo'),
          backgroundColor: Colors.black87,
        ),
        body: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            if (!isGameStarted) startGame();
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 10) {
              moveRight();
            } else if (details.delta.dx < -10) {
              moveLeft();
            }
          },
          child: Container(
            // plus de background image : on laisse le fond par défaut du Scaffold
            child: Stack(
              children: [
                _buildRoad(),
                ...obstacles.map((obstacle) => _buildObstacleItem(obstacle)),
                _buildPlayerPacman(),

                // Score
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.yellow, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars,
                            color: Colors.yellow, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Meilleur score
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          '${widget.user.carGameScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Écran de démarrage
                if (!isGameStarted)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(220),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.green, width: 3),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco,
                              size: 80, color: Colors.green),
                          const SizedBox(height: 20),
                          const Text(
                            'Pacman Écolo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Mange le soleil, l’eau, les arbres,\nmais évite les poubelles !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow,
                                    size: 30, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'DÉMARRER',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Boutons gauche/droite
                if (isGameStarted && !isGameOver)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton.large(
                          heroTag: 'left',
                          onPressed: moveLeft,
                          backgroundColor: Colors.blue,
                          child:
                          const Icon(Icons.arrow_back, size: 40),
                        ),
                        FloatingActionButton.large(
                          heroTag: 'right',
                          onPressed: moveRight,
                          backgroundColor: Colors.blue,
                          child:
                          const Icon(Icons.arrow_forward, size: 40),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoad() {
    return Row(
      children: [
        Expanded(child: Container(color: Colors.transparent)),
        Container(width: 4, color: Colors.white),
        Expanded(child: Container(color: Colors.transparent)),
        Container(width: 4, color: Colors.white),
        Expanded(child: Container(color: Colors.transparent)),
        Container(width: 4, color: Colors.white),
        Expanded(child: Container(color: Colors.transparent)),
      ],
    );
  }

  Widget _buildPlayerPacman() {
    double laneWidth = MediaQuery.of(context).size.width / 4;

    return Positioned(
      bottom: 100,
      left: playerLane * laneWidth + laneWidth * 0.25,
      child: SizedBox(
        width: laneWidth * 0.5,
        height: laneWidth * 0.5,
        child: Image.asset(
          AppAssets.pacman,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildObstacleItem(Obstacle obstacle) {
    double screenHeight = MediaQuery.of(context).size.height;
    double laneWidth = MediaQuery.of(context).size.width / 4;

    // Images correctes (vrai) et incorrectes (faute) depuis assets/imagee
    List<String> vrais = [
      'assets/images/vrai1.webp',
      'assets/images/vrai2.webp',
      'assets/images/vrai3.webp',
      'assets/images/vrai4.webp',
    ];

    List<String> faux = [
      'assets/images/faute1.webp',
      'assets/images/faute2.webp',
      'assets/images/faute3.webp',
      'assets/images/faute4.webp',
    ];

    String imagePath =
    obstacle.isGood ? vrais[obstacle.typeIndex] : faux[obstacle.typeIndex];

    return Positioned(
      top: obstacle.y * screenHeight,
      left: obstacle.lane * laneWidth + laneWidth * 0.25,
      child: SizedBox(
        width: laneWidth * 0.4,
        height: laneWidth * 0.4,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class Obstacle {
  int lane;
  double y;
  bool isGood;
  int typeIndex;

  Obstacle({
    required this.lane,
    required this.y,
    required this.isGood,
    required this.typeIndex,
  });
}
