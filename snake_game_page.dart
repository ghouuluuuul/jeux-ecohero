import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

enum Direction { up, down, left, right }

class SnakeGamePage extends StatefulWidget {
  final UserModel user;

  const SnakeGamePage({super.key, required this.user});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  static const int gridSize = 15; // RÉDUIT POUR CASES PLUS GRANDES
  static const int initialSpeed = 250;

  List<Point<int>> snake = [];
  Point<int> food = const Point(7, 7);
  Direction direction = Direction.right;
  Direction? nextDirection;

  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  int bestScore = 0;
  int speed = initialSpeed;

  Timer? gameTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    bestScore = widget.user.snakeGameScore;
    _initGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _initGame() {
    snake = [
      const Point(5, 7),
      const Point(4, 7),
      const Point(3, 7),
    ];
    direction = Direction.right;
    nextDirection = null;
    _generateFood();
    score = 0;
    speed = initialSpeed;
    isGameOver = false;
  }

  void _startGame() {
    if (isPlaying) return;

    setState(() {
      isPlaying = true;
      if (isGameOver) {
        _initGame();
      }
    });

    _focusNode.requestFocus();

    gameTimer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      _update();
    });
  }

  void _pauseGame() {
    setState(() {
      isPlaying = false;
    });
    gameTimer?.cancel();
  }

  void _update() {
    if (!isPlaying) return;

    if (nextDirection != null) {
      direction = nextDirection!;
      nextDirection = null;
    }

    Point<int> head = snake.first;
    Point<int> newHead;

    switch (direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    if (newHead.x < 0 || newHead.x >= gridSize || newHead.y < 0 || newHead.y >= gridSize) {
      _gameOver();
      return;
    }

    if (snake.contains(newHead)) {
      _gameOver();
      return;
    }

    setState(() {
      snake.insert(0, newHead);

      if (newHead == food) {
        score += 10;
        _generateFood();

        if (score % 50 == 0 && speed > 100) {
          speed -= 20;
          gameTimer?.cancel();
          gameTimer = Timer.periodic(Duration(milliseconds: speed), (timer) {
            _update();
          });
        }
      } else {
        snake.removeLast();
      }
    });
  }

  void _generateFood() {
    Random random = Random();
    Point<int> newFood;

    do {
      newFood = Point(random.nextInt(gridSize), random.nextInt(gridSize));
    } while (snake.contains(newFood));

    food = newFood;
  }

  void _changeDirection(Direction newDirection) {
    if ((direction == Direction.up && newDirection == Direction.down) ||
        (direction == Direction.down && newDirection == Direction.up) ||
        (direction == Direction.left && newDirection == Direction.right) ||
        (direction == Direction.right && newDirection == Direction.left)) {
      return;
    }

    nextDirection = newDirection;
  }

  void _handleKeyPress(KeyEvent event) {
    if (!isPlaying) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          _startGame();
        }
      }
      return;
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _changeDirection(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _changeDirection(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _changeDirection(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _changeDirection(Direction.right);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _pauseGame();
      }
    }
  }

  Future<void> _gameOver() async {
    gameTimer?.cancel();

    setState(() {
      isPlaying = false;
      isGameOver = true;
    });

    if (score > bestScore) {
      await DatabaseService.instance.updateScore(
        userId: widget.user.id!,
        gameType: 'snakeGame',
        score: score,
      );
      widget.user.snakeGameScore = score;
      bestScore = score;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '🐍 Game Over',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.snakeGameColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.snakeGameColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Meilleur: $bestScore',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (score > bestScore) ...[
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
              _initGame();
              _startGame();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.snakeGame),
        backgroundColor: AppColors.snakeGameColor,
      ),
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          _handleKeyPress(event);
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.snakeGameColor,
                  AppColors.snakeGameColor.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Score Panel
                  Container(
                    margin: const EdgeInsets.all(15),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              'Score: $score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              'Record: $bestScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Grille de jeu PLUS GRANDE
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize,
                            ),
                            itemCount: gridSize * gridSize,
                            itemBuilder: (context, index) {
                              int x = index % gridSize;
                              int y = index ~/ gridSize;
                              Point<int> point = Point(x, y);

                              bool isSnakeBody = snake.contains(point);
                              bool isHead = snake.isNotEmpty && snake.first == point;
                              bool isFood = food == point;

                              return Container(
                                margin: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: isHead
                                      ? Colors.green.shade700
                                      : isSnakeBody
                                      ? Colors.green
                                      : isFood
                                      ? Colors.red
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: isFood ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    )
                                  ] : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Instructions
                  if (!isPlaying && !isGameOver)
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.keyboard,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            '⌨️ Utilisez les flèches du clavier',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '⬆️ ⬇️ ⬅️ ➡️',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ESPACE pour démarrer/pause',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.snakeGameColor,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, size: 32),
                                SizedBox(width: 12),
                                Text(
                                  'JOUER',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bouton Pause pendant le jeu
                  if (isPlaying)
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: ElevatedButton(
                        onPressed: _pauseGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'PAUSE (ESPACE)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
