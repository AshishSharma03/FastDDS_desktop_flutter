import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _channel = MethodChannel('counter_channel');
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  Future<void> _loadCounter() async {
    try {
      final value = await _channel.invokeMethod<int>('get');
      setState(() => _counter = value ?? 0);
    } on PlatformException catch (e) {
      debugPrint('get error: $e');
    }
  }

  Future<void> _increment() async {
    try {
      final value = await _channel.invokeMethod<int>('increment');
      setState(() => _counter = value ?? _counter);
    } on PlatformException catch (e) {
      debugPrint('increment error: $e');
    }
  }

  Future<void> _reset() async {
    try {
      final value = await _channel.invokeMethod<int>('reset');
      setState(() => _counter = value ?? 0);
    } on PlatformException catch (e) {
      debugPrint('reset error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter Desktop + C++ Counter')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Counter value from C++:', style: TextStyle(fontSize: 18)),
              Text('$_counter', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton(onPressed: _increment, child: const Text('Increment (C++)')),
                  OutlinedButton(onPressed: _reset, child: const Text('Reset (C++)')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
