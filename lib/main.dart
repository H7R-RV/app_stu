import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() => runApp(const TestGeneratorApp());

class TestGeneratorApp extends StatelessWidget {
  const TestGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Test Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme(),
        home: const HomeScreen(),
      ),
    );
  }
}
