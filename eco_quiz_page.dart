import 'package:flutter/material.dart';

enum AppLanguage { fr, ar, en }

class EcoQuizPage extends StatefulWidget {
  const EcoQuizPage({super.key});

  @override
  State<EcoQuizPage> createState() => _EcoQuizPageState();
}

class _EcoQuizPageState extends State<EcoQuizPage> {
  AppLanguage _lang = AppLanguage.fr;

  late List<_Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool? _lastAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    _questions = _questionsByLang[_lang]!;
    _currentIndex = 0;
    _score = 0;
    _answered = false;
    _lastAnswerCorrect = null;
  }

  void _changeLanguage(AppLanguage lang) {
    setState(() {
      _lang = lang;
      _loadQuestions();
    });
  }

  bool get _isArabic => _lang == AppLanguage.ar;

  void _answer(bool value) {
    if (_answered) return;

    final current = _questions[_currentIndex];
    final correct = current.isTrue == value;

    setState(() {
      _answered = true;
      _lastAnswerCorrect = correct;
      if (correct) _score++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          correct ? _txt('snack_correct') : _txt('snack_wrong'),
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _lastAnswerCorrect = null;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(_txt('result_title')),
          content: Text('${_txt('score_label')} $_score / ${_questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _loadQuestions();
                });
              },
              child: Text(_txt('play_again')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_txt('close')),
            ),
          ],
        ),
      ),
    );
  }

  String _txt(String key) {
    switch (_lang) {
      case AppLanguage.fr:
        switch (key) {
          case 'title':
            return 'Quiz Écologie';
          case 'question_label':
            return 'Question';
          case 'score_title':
            return 'Score';
          case 'true':
            return 'Vrai';
          case 'false':
            return 'Faux';
          case 'snack_correct':
            return '✅ Bonne réponse !';
          case 'snack_wrong':
            return '❌ Mauvaise réponse.';
          case 'explain_good':
            return 'Ce geste est bon pour la planète.';
          case 'explain_bad':
            return 'Ce geste peut polluer ou gaspiller des ressources.';
          case 'next':
            return 'Question suivante';
          case 'show_result':
            return 'Voir le résultat';
          case 'result_title':
            return 'Quiz terminé';
          case 'score_label':
            return 'Score :';
          case 'play_again':
            return 'Rejouer';
          case 'close':
            return 'Fermer';
        }
        break;
      case AppLanguage.ar:
        switch (key) {
          case 'title':
            return 'اختبار البيئة';
          case 'question_label':
            return 'السؤال';
          case 'score_title':
            return 'النتيجة';
          case 'true':
            return 'صحيح';
          case 'false':
            return 'خطأ';
          case 'snack_correct':
            return '✅ إجابة صحيحة!';
          case 'snack_wrong':
            return '❌ إجابة خاطئة.';
          case 'explain_good':
            return 'هذا السلوك مفيد للبيئة.';
          case 'explain_bad':
            return 'هذا السلوك قد يسبب تلوثًا أو هدراً للموارد.';
          case 'next':
            return 'السؤال التالي';
          case 'show_result':
            return 'عرض النتيجة';
          case 'result_title':
            return 'انتهى الاختبار';
          case 'score_label':
            return 'النتيجة:';
          case 'play_again':
            return 'إعادة المحاولة';
          case 'close':
            return 'إغلاق';
        }
        break;
      case AppLanguage.en:
        switch (key) {
          case 'title':
            return 'Eco Quiz';
          case 'question_label':
            return 'Question';
          case 'score_title':
            return 'Score';
          case 'true':
            return 'True';
          case 'false':
            return 'False';
          case 'snack_correct':
            return '✅ Correct answer!';
          case 'snack_wrong':
            return '❌ Wrong answer.';
          case 'explain_good':
            return 'This action is good for the planet.';
          case 'explain_bad':
            return 'This action can cause pollution or waste resources.';
          case 'next':
            return 'Next question';
          case 'show_result':
            return 'Show result';
          case 'result_title':
            return 'Quiz finished';
          case 'score_label':
            return 'Score:';
          case 'play_again':
            return 'Play again';
          case 'close':
            return 'Close';
        }
        break;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_txt('title')),
          backgroundColor: Colors.teal.shade800,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade900,
                Colors.green.shade900,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sélecteur de langue
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Français'),
                        selected: _lang == AppLanguage.fr,
                        onSelected: (_) => _changeLanguage(AppLanguage.fr),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('العربية'),
                        selected: _lang == AppLanguage.ar,
                        onSelected: (_) => _changeLanguage(AppLanguage.ar),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('English'),
                        selected: _lang == AppLanguage.en,
                        onSelected: (_) => _changeLanguage(AppLanguage.en),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_txt('question_label')} ${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_txt('score_title')}: $_score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      q.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _answer(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check),
                    label: Text(
                      _txt('true'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _answer(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close),
                    label: Text(
                      _txt('false'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const Spacer(),
                  if (_answered)
                    Text(
                      _lastAnswerCorrect == true
                          ? _txt('explain_good')
                          : _txt('explain_bad'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: _isArabic
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal.shade900,
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? _txt('next')
                            : _txt('show_result'),
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

class _Question {
  final String text;
  final bool isTrue;

  _Question({required this.text, required this.isTrue});
}

final Map<AppLanguage, List<_Question>> _questionsByLang = {
  AppLanguage.fr: [
    _Question(
      text:
      'Éteindre la lumière en quittant une pièce permet d\'économiser de l\'énergie.',
      isTrue: true,
    ),
    _Question(
      text:
      'Jeter des piles à la poubelle classique n\'a aucun impact sur l\'environnement.',
      isTrue: false,
    ),
    _Question(
      text:
      'Boire l\'eau du robinet est en général plus écologique que l\'eau en bouteille.',
      isTrue: true,
    ),
    _Question(
      text:
      'Le plastique se dégrade complètement dans la nature en quelques semaines.',
      isTrue: false,
    ),
    _Question(
      text: 'Planter des arbres aide à absorber le dioxyde de carbone (CO₂).',
      isTrue: true,
    ),
  ],
  AppLanguage.ar: [
    _Question(
      text: 'إطفاء الأضواء عند مغادرة الغرفة يساعد على توفير الطاقة.',
      isTrue: true,
    ),
    _Question(
      text: 'رمي البطاريات في سلة المهملات العادية لا يضر بالبيئة.',
      isTrue: false,
    ),
    _Question(
      text: 'شرب ماء الحنفية غالبًا أكثر صداقة للبيئة من الماء المعبأ.',
      isTrue: true,
    ),
    _Question(
      text: 'البلاستيك يتحلل بالكامل خلال أسابيع قليلة في الطبيعة.',
      isTrue: false,
    ),
    _Question(
      text: 'زرع الأشجار يساعد على امتصاص غاز ثاني أكسيد الكربون (CO₂).',
      isTrue: true,
    ),
  ],
  AppLanguage.en: [
    _Question(
      text: 'Turning off the light when leaving a room saves energy.',
      isTrue: true,
    ),
    _Question(
      text: 'Throwing batteries in a normal trash bin has no effect on nature.',
      isTrue: false,
    ),
    _Question(
      text:
      'Drinking tap water is usually more eco‑friendly than bottled water.',
      isTrue: true,
    ),
    _Question(
      text: 'Plastic completely decomposes in nature within a few weeks.',
      isTrue: false,
    ),
    _Question(
      text: 'Planting trees helps absorb carbon dioxide (CO₂).',
      isTrue: true,
    ),
  ],
};
