import 'package:flutter/material.dart';

enum AppLanguage { fr, ar, en }
enum WasteType { recyclable, organic, other }

class WasteItem {
  final String name;
  final WasteType type;

  WasteItem({required this.name, required this.type});
}

class RecyclingGamePage extends StatefulWidget {
  const RecyclingGamePage({super.key});

  @override
  State<RecyclingGamePage> createState() => _RecyclingGamePageState();
}

class _RecyclingGamePageState extends State<RecyclingGamePage> {
  AppLanguage _lang = AppLanguage.fr;

  late List<WasteItem> _items;
  int _score = 0;
  int _total = 0;

  bool get _isArabic => _lang == AppLanguage.ar;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _changeLanguage(AppLanguage lang) {
    setState(() {
      _lang = lang;
      _loadItems();
    });
  }

  void _loadItems() {
    _items = List<WasteItem>.from(_itemsByLang[_lang]!);
    _items.shuffle();
    _score = 0;
    _total = _items.length;
  }

  void _handleDrop(WasteItem item, WasteType targetType) {
    final bool isCorrect = item.type == targetType;

    setState(() {
      _items.remove(item);
      if (isCorrect) _score++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? _txt('snack_correct') : _txt('snack_wrong', item.name),
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );

    if (_items.isEmpty) {
      _showEndDialog();
    }
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(_txt('end_title')),
          content: Text('${_txt('score')} $_score / $_total'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _loadItems();
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

  String _txt(String key, [String name = '']) {
    switch (_lang) {
      case AppLanguage.fr:
        switch (key) {
          case 'title':
            return 'Tri des déchets';
          case 'score':
            return 'Score :';
          case 'instruction':
            return 'Glisse chaque déchet dans la bonne poubelle : Recyclable, Organique ou Autres déchets.';
          case 'bin_recyclable':
            return 'Recyclable';
          case 'bin_organic':
            return 'Organique';
          case 'bin_other':
            return 'Autres déchets';
          case 'snack_correct':
            return 'Bien joué !';
          case 'snack_wrong':
            return 'Mauvais bac pour "$name".';
          case 'end_title':
            return 'Partie terminée';
          case 'play_again':
            return 'Rejouer';
          case 'close':
            return 'Fermer';
        }
        break;

      case AppLanguage.ar:
        switch (key) {
          case 'title':
            return 'لعبة فرز النفايات';
          case 'score':
            return 'النتيجة:';
          case 'instruction':
            return 'اسحب كل نوع من النفايات إلى الحاوية المناسبة: قابلة لإعادة التدوير، عضوية أو نفايات أخرى.';
          case 'bin_recyclable':
            return 'إعادة التدوير';
          case 'bin_organic':
            return 'نفايات عضوية';
          case 'bin_other':
            return 'نفايات أخرى';
          case 'snack_correct':
            return 'أحسنت! تم وضع النفاية في السلة الصحيحة.';
          case 'snack_wrong':
            return 'سلة غير صحيحة لـ "$name".';
          case 'end_title':
            return 'انتهت اللعبة';
          case 'play_again':
            return 'إعادة اللعب';
          case 'close':
            return 'إغلاق';
        }
        break;

      case AppLanguage.en:
        switch (key) {
          case 'title':
            return 'Waste Sorting Game';
          case 'score':
            return 'Score:';
          case 'instruction':
            return 'Drag each waste item to the correct bin: Recyclable, Organic or Other waste.';
          case 'bin_recyclable':
            return 'Recyclable';
          case 'bin_organic':
            return 'Organic';
          case 'bin_other':
            return 'Other waste';
          case 'snack_correct':
            return 'Well done! Correct bin.';
          case 'snack_wrong':
            return 'Wrong bin for "$name".';
          case 'end_title':
            return 'Game finished';
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
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_txt('title')),
          backgroundColor: Colors.green.shade800,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade900,
                Colors.blueGrey.shade900,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Text(
                  '${_txt('score')} $_score / $_total',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _txt('instruction'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),

                // Objets à trier
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final WasteItem item = _items[index];
                      return Draggable<WasteItem>(
                        data: item,
                        feedback: _buildItemChip(item, isDragging: true),
                        childWhenDragging: _buildItemChip(
                          item,
                          isDragging: false,
                          faded: true,
                        ),
                        child: _buildItemChip(item, isDragging: false),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Bacs
                Expanded(
                  child: Row(
                    children: [
                      _buildBinColumn(
                        _txt('bin_recyclable'),
                        Icons.recycling,
                        Colors.lightGreenAccent,
                        WasteType.recyclable,
                      ),
                      _buildBinColumn(
                        _txt('bin_organic'),
                        Icons.eco,
                        Colors.orangeAccent,
                        WasteType.organic,
                      ),
                      _buildBinColumn(
                        _txt('bin_other'),
                        Icons.delete,
                        Colors.redAccent,
                        WasteType.other,
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

  Widget _buildBinColumn(
      String title,
      IconData icon,
      Color color,
      WasteType targetType,
      ) {
    return Expanded(
      child: DragTarget<WasteItem>(
        onWillAccept: (data) => true,
        onAccept: (item) => _handleDrop(item, targetType),
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: candidateData.isNotEmpty ? Colors.white : color,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemChip(
      WasteItem item, {
        required bool isDragging,
        bool faded = false,
      }) {
    return Opacity(
      opacity: faded ? 0.3 : 1.0,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDragging ? Colors.white : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.type == WasteType.recyclable
                  ? Icons.recycling
                  : item.type == WasteType.organic
                  ? Icons.eco
                  : Icons.delete,
              color: item.type == WasteType.recyclable
                  ? Colors.green
                  : item.type == WasteType.organic
                  ? Colors.orange
                  : Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final Map<AppLanguage, List<WasteItem>> _itemsByLang = {
  AppLanguage.fr: [
    WasteItem(name: 'Bouteille en plastique', type: WasteType.recyclable),
    WasteItem(name: 'Journal / papier', type: WasteType.recyclable),
    WasteItem(name: 'Canette en aluminium', type: WasteType.recyclable),
    WasteItem(name: 'Épluchures de légumes', type: WasteType.organic),
    WasteItem(name: 'Pomme', type: WasteType.organic),
    WasteItem(name: 'Feuilles mortes', type: WasteType.organic),
    WasteItem(name: 'Pile / batterie', type: WasteType.other),
    WasteItem(name: 'Sac en plastique', type: WasteType.other),
    WasteItem(name: 'Verre cassé', type: WasteType.other),
  ],
  AppLanguage.ar: [
    WasteItem(name: 'قارورة بلاستيكية', type: WasteType.recyclable),
    WasteItem(name: 'جريدة / ورق', type: WasteType.recyclable),
    WasteItem(name: 'علبة ألومنيوم', type: WasteType.recyclable),
    WasteItem(name: 'قشور الخضار', type: WasteType.organic),
    WasteItem(name: 'تفاحة', type: WasteType.organic),
    WasteItem(name: 'أوراق شجر يابسة', type: WasteType.organic),
    WasteItem(name: 'بطارية', type: WasteType.other),
    WasteItem(name: 'كيس بلاستيك', type: WasteType.other),
    WasteItem(name: 'زجاج مكسور', type: WasteType.other),
  ],
  AppLanguage.en: [
    WasteItem(name: 'Plastic bottle', type: WasteType.recyclable),
    WasteItem(name: 'Newspaper / paper', type: WasteType.recyclable),
    WasteItem(name: 'Aluminium can', type: WasteType.recyclable),
    WasteItem(name: 'Vegetable peels', type: WasteType.organic),
    WasteItem(name: 'Apple', type: WasteType.organic),
    WasteItem(name: 'Dry leaves', type: WasteType.organic),
    WasteItem(name: 'Battery', type: WasteType.other),
    WasteItem(name: 'Plastic bag', type: WasteType.other),
    WasteItem(name: 'Broken glass', type: WasteType.other),
  ],
};
