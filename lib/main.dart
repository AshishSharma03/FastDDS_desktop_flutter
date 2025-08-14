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

  Future<void> _startPublisher() async {
    try {
      await _channel.invokeMethod('startPublisher');
      debugPrint('Publisher started');
    } on PlatformException catch (e) {
      debugPrint('startPublisher error: $e');
    }
  }

  Future<void> _startSubscriber() async {
    try {
      await _channel.invokeMethod('startSubscriber');
      debugPrint('Subscriber started');
    } on PlatformException catch (e) {
      debugPrint('startSubscriber error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter Desktop DDS Example')),
        body: Center(
          child: Wrap(
            spacing: 16,
            children: [
              ElevatedButton(
                onPressed: _startPublisher,
                child: const Text('Start Publisher'),
              ),
              ElevatedButton(
                onPressed: _startSubscriber,
                child: const Text('Start Subscriber'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
