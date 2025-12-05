import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class NumberPuzzlePage extends StatefulWidget {
  final UserModel user;

  const NumberPuzzlePage({super.key, required this.user});

  @override
  State<NumberPuzzlePage> createState() => _NumberPuzzlePageState();
}

class _NumberPuzzlePageState extends State<NumberPuzzlePage> {
  List<int> tiles = [];
  int emptyIndex = 15;
  int moves = 0;
  int timeSeconds = 0;
  Timer? timer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initGame();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeSeconds++;
      });
    });
  }

  void _initGame() {
    tiles = List.generate(16, (index) => index);
    _shuffle();
    moves = 0;
    timeSeconds = 0;
    setState(() {});
  }

  void _shuffle() {
    final random = Random();
    for (int i = 0; i < 100; i++) {
      List<int> validMoves = _getValidMoves();
      if (validMoves.isNotEmpty) {
        int randomMove = validMoves[random.nextInt(validMoves.length)];
        _moveTile(randomMove, countMove: false);
      }
    }
  }

  List<int> _getValidMoves() {
    List<int> validMoves = [];
    int row = emptyIndex ~/ 4;
    int col = emptyIndex % 4;

    if (row > 0) validMoves.add(emptyIndex - 4);
    if (row < 3) validMoves.add(emptyIndex + 4);
    if (col > 0) validMoves.add(emptyIndex - 1);
    if (col < 3) validMoves.add(emptyIndex + 1);

    return validMoves;
  }

  void _moveTile(int index, {bool countMove = true}) {
    if (_getValidMoves().contains(index)) {
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
        emptyIndex = index;
        if (countMove) moves++;
      });

      if (_checkWin()) {
        timer?.cancel();
        _showWinDialog();
      }
    }
  }

  bool _checkWin() {
    for (int i = 0; i < 15; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles[15] == 0;
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      int row = emptyIndex ~/ 4;
      int col = emptyIndex % 4;

      if (event.logicalKey == LogicalKeyboardKey.arrowUp && row < 3) {
        _moveTile(emptyIndex + 4);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && row > 0) {
        _moveTile(emptyIndex - 4);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && col < 3) {
        _moveTile(emptyIndex + 1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && col > 0) {
        _moveTile(emptyIndex - 1);
      }
    }
  }

  Future<void> _showWinDialog() async {
    // Calculer le score (moins de coups et de temps = meilleur score)
    int score = 10000 - (moves * 10) - timeSeconds;
    if (score < 0) score = 0;

    // Sauvegarder le score
    await DatabaseService.instance.updateScore(
      userId: widget.user.id!,
      gameType: 'puzzle',
      score: score,
    );

    // Mettre à jour l'objet user
    if (score > widget.user.puzzleScore) {
      widget.user.puzzleScore = score;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          AppStrings.congratulations,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              'Vous avez résolu le puzzle !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.puzzleColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.puzzleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coups: $moves',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Temps: ${_formatTime(timeSeconds)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              timer?.cancel();
              _initGame();
              _startTimer();
            },
            child: const Text(AppStrings.newGame),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text(AppStrings.menu),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.puzzle),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(timeSeconds),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Coups: $moves',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                timer?.cancel();
                _initGame();
                _startTimer();
              },
              tooltip: AppStrings.newGame,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 320,
                height: 320,
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    int value = tiles[index];
                    bool isEmpty = value == 0;

                    return DragTarget<int>(
                      onAccept: (draggedIndex) {
                        if (_getValidMoves().contains(draggedIndex)) {
                          _moveTile(draggedIndex);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: candidateData.isNotEmpty
                                  ? Border.all(
                                color: AppColors.accent,
                                width: 3,
                              )
                                  : null,
                            ),
                          );
                        }

                        return Draggable<int>(
                          data: index,
                          feedback: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: AppColors.puzzleColor.withAlpha(200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$value',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onDragCompleted: () {
                            _focusNode.requestFocus();
                          },
                          child: GestureDetector(
                            onTap: () {
                              _moveTile(index);
                              _focusNode.requestFocus();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.puzzleColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$value',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
