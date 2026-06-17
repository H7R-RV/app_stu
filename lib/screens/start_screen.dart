import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'generator_wizard.dart';

/// Landing screen: choose between the auto paper generator and the design canvas.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deskGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 64, color: AppTheme.seed),
                    const SizedBox(height: 12),
                    const Text('Test Paper Studio',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Generate exam papers automatically, or design them freely.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 28),
                    _card(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'Auto-Generate Paper',
                      subtitle:
                          'Pick sections, marks, difficulty & sets. We build the paper, answer key and shuffled variants for you.',
                      gradient: AppTheme.appBarGradient,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const GeneratorWizard())),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      context,
                      icon: Icons.design_services,
                      title: 'Design Studio (Canva-style)',
                      subtitle:
                          'Free canvas: drag text, shapes, images & question blocks anywhere with full styling.',
                      gradient: AppTheme.fabGradient,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const HomeScreen())),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Gradient gradient,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
