import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaCard extends StatefulWidget {
  final String name;      // ici : titre de la vidéo
  final IconData icon;    // icône (play)
  final Color color;      // couleur du dégradé
  final String url;       // lien de la vidéo (YouTube, etc.)

  const SocialMediaCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.url,
  });

  @override
  State<SocialMediaCard> createState() => _SocialMediaCardState();
}

class _SocialMediaCardState extends State<SocialMediaCard> {
  bool _isHovered = false;

  Future<void> _launchURL() async {
    final Uri uri = Uri.parse(widget.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir ${widget.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: Card(
          elevation: _isHovered ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _launchURL,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
