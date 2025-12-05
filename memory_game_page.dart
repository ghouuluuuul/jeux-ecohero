import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class MemoryGamePage extends StatefulWidget {
  final UserModel user;

  const MemoryGamePage({super.key, required this.user});

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  List<MemoryCard> cards = [];
  List<int> selectedCards = [];
  int moves = 0;
  int matches = 0;
  bool isChecking = false;
  bool isGameStarted = false;
  int bestScore = 0;

  // 12 PAIRES = 24 CARTES, images environnement
  final List<String> images = [
    'assets/images/soleil.webp',
    'assets/images/arbre.webp',
    'assets/images/eau.webp',
    'assets/images/fleur.webp',
    'assets/images/terre.webp',
    'assets/images/vent.webp',
    'assets/images/montagne.webp',
    'assets/images/oiseau.webp',
    'assets/images/herbe.webp',
    'assets/images/nuage.webp',
    'assets/images/feuille.webp',
    'assets/images/recyclage.webp',
  ];

  @override
  void initState() {
    super.initState();
    bestScore = widget.user.memoryGameScore;
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      moves = 0;
      matches = 0;
      selectedCards.clear();
      cards.clear();

      // Créer les paires de cartes (images)
      for (int i = 0; i < images.length; i++) {
        cards.add(MemoryCard(
          id: i * 2,
          imagePath: images[i],
          isMatched: false,
        ));
        cards.add(MemoryCard(
          id: i * 2 + 1,
          imagePath: images[i],
          isMatched: false,
        ));
      }

      // Mélanger les cartes
      cards.shuffle(Random());
    });
  }

  void onCardTap(int index) {
    if (isChecking ||
        selectedCards.contains(index) ||
        cards[index].isMatched ||
        selectedCards.length >= 2) {
      return;
    }

    setState(() {
      selectedCards.add(index);
    });

    if (selectedCards.length == 2) {
      setState(() {
        moves++;
        isChecking = true;
      });

      Timer(const Duration(milliseconds: 1000), () {
        checkMatch();
      });
    }
  }

  void checkMatch() {
    int first = selectedCards[0];
    int second = selectedCards[1];

    if (cards[first].imagePath == cards[second].imagePath) {
      // Match trouvé !
      setState(() {
        cards[first].isMatched = true;
        cards[second].isMatched = true;
        matches++;
      });

      // Vérifier si le jeu est terminé
      if (matches == images.length) {
        gameOver();
      }
    }

    setState(() {
      selectedCards.clear();
      isChecking = false;
    });
  }

  Future<void> gameOver() async {
    // Le score est basé sur le nombre de mouvements (moins = mieux)
    int score = 1500 - (moves * 10);
    if (score < 0) score = 0;

    await DatabaseService.instance.updateScore(
      userId: widget.user.id!,
      gameType: 'memoryGame',
      score: score,
    );

    if (score > widget.user.memoryGameScore) {
      widget.user.memoryGameScore = score;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '🎉 Bravo !',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              'Vous avez gagné !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.memoryGameColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Mouvements: $moves',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.memoryGameColor,
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.memoryGame),
        backgroundColor: AppColors.memoryGameColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.memoryGameColor,
              AppColors.memoryGameColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Score panel
              if (isGameStarted)
                Container(
                  margin: const EdgeInsets.all(15),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.touch_app,
                              color: Colors.white, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            'Coups: $moves',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            'Paires: $matches/${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Colors.amber, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            'Record: $bestScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Game grid - SCROLL HORIZONTAL
              if (isGameStarted)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: SizedBox(
                          height:
                          MediaQuery.of(context).size.height * 0.65,
                          child: GridView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6, // 6 lignes
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              return _buildCard(index);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Start screen
              if (!isGameStarted)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.psychology,
                            size: 100,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            '🧠 Jeu de Mémoire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Trouvez toutes les paires d’images environnementales\nen un minimum de coups !',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '📝 Comment jouer:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '1. Cliquez sur deux cartes\n'
                                      '2. Si les images sont identiques, elles restent visibles\n'
                                      '3. Sinon, elles se retournent\n'
                                      '4. Trouvez toutes les ${images.length} paires !\n\n'
                                      '⬅️ Faites défiler horizontalement ➡️',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                              AppColors.memoryGameColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  'JOUER',
                                  style: TextStyle(
                                    fontSize: 24,
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    bool isFlipped =
        selectedCards.contains(index) || cards[index].isMatched;

    return GestureDetector(
      onTap: () => onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isFlipped ? Colors.white : Colors.purple.shade300,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isFlipped
              ? Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              cards[index].imagePath,
              fit: BoxFit.contain,
            ),
          )
              : const Icon(
            Icons.help_outline,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class MemoryCard {
  final int id;
  final String imagePath;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.imagePath,
    required this.isMatched,
  });
}
