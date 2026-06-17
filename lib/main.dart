import 'package:flutter/material.dart';

void main() => runApp(const SimpleDemoApp());

class SimpleDemoApp extends StatelessWidget {
  const SimpleDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Demo'),
        backgroundColor: scheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flutter_dash, size: 96, color: scheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Hello from Flutter! 👋',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Text(
              'You have tapped the button',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            Text(
              '$_count',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _count == 1 ? 'time' : 'times',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_count > 0)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: FloatingActionButton(
                heroTag: 'reset',
                onPressed: () => setState(() => _count = 0),
                tooltip: 'Reset',
                child: const Icon(Icons.refresh),
              ),
            ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => setState(() => _count++),
            icon: const Icon(Icons.add),
            label: const Text('Tap me'),
          ),
        ],
      ),
    );
  }
}
