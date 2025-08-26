import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'global_variables.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROG Controller with FastDDS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const GamepadHomePage(),
    );
  }
}

class GamepadHomePage extends StatefulWidget {
  const GamepadHomePage({super.key});

  @override
  State<GamepadHomePage> createState() => _GamepadHomePageState();
}

class _GamepadHomePageState extends State<GamepadHomePage> {
  // FastDDS Channel
  static const _channel = MethodChannel('counter_channel');
  Timer? _publisherTimer;
  String _currentMessage = "0";

  // Gamepad Variables
  List<GamepadController> _connectedGamepads = [];
  String _log = 'Waiting for input...';
  final Set<String> _seenKeys = {};

  // Variables mapped to controller
  double xL = 0.0; // Left Stick X
  double yR = 0.0; // Right Stick Y
  int xH = -1;     // POV Hat Switch (-1 = neutral)

  // Button states
  bool button0Pressed = false;
  bool button1Pressed = false;
  bool button2Pressed = false;
  bool button3Pressed = false;
  bool button4Pressed = false;
  bool button5Pressed = false;
  double dwzPos = 32768.0;      // Z-axis position (throttle/trigger)

  String _lastKeyEvent = "";
  String _lastActuatorEvent = "";

  @override
  void initState() {
    super.initState();
    _setupGamepad();
  }

  @override
  void dispose() {
    _publisherTimer?.cancel();
    super.dispose();
  }

  // FastDDS Methods
  Future<void> _startPublisher() async {
    try {
      await _channel.invokeMethod('startPublisher');
      debugPrint('Publisher started');

      // Cancel old timer if running
      _publisherTimer?.cancel();

      // Start sending immediately + then periodically
      _sendMessage(_currentMessage);
      _publisherTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        _sendMessage(_currentMessage);
      });
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

  Future<void> _stopPublisher() async {
    try {
      await _channel.invokeMethod('stopPublisher');
      debugPrint('Stop Publisher');
    } on PlatformException catch (e) {
      debugPrint('Stop Publisher error: $e');
    }
  }

  Future<void> _sendMessage(String msg) async {
    try {
      await _channel.invokeMethod('SentMsg', msg);
      debugPrint('Sent message: $msg');
    } on PlatformException catch (e) {
      debugPrint('sendMessage error: $e');
    }
  }

  // Gamepad Methods
  double _normalizeAxis(num rawValue) {
    // Raw joystick values: 0 → 65535
    // Normalized: -1.0 → 1.0
    return ((rawValue - 32768) / 32768).clamp(-1.0, 1.0);
  }

  void _updateMotorData() {
    String oldMotorData = _currentMessage;

    // Default state
    motorData = '0';

    // --- Button 0-3 continuous check ---
    if (button0Pressed) {
      motorData = "a";
    } else if (button1Pressed) {
      motorData = "b";
    } else if (button2Pressed) {
      motorData = "c";
    } else if (button3Pressed) {
      motorData = "d";
    }
    // --- POV combinations take priority (5,6,7,8) ---
    else if (yR < -0.5 && xH == 27000) {
      motorData = '5';
    } else if (yR < -0.5 && xH == 9000) {
      motorData = '6';
    } else if (yR > 0.5 && xH == 27000) {
      motorData = '7';
    } else if (yR > 0.5 && xH == 9000) {
      motorData = '8';
    }
    // --- Basic stick movements (1,2,3,4) ---
    else if (yR < -0.5 && xL.abs() < 0.5) {
      motorData = '1';
    } else if (yR > 0.5 && xL.abs() < 0.5) {
      motorData = '2';
    } else if (xL < -0.5 && yR.abs() < 0.5) {
      motorData = '3';
    } else if (xL > 0.5 && yR.abs() < 0.5) {
      motorData = '4';
    }

    // Update current message for FastDDS
    _currentMessage = motorData;

    // Send via FastDDS if message changed
    if (oldMotorData != _currentMessage && _publisherTimer != null) {
      _sendMessage(_currentMessage);
    }

    print("motorData: $motorData (xL: $xL, yR: $yR, xH: $xH, Btn0:$button0Pressed Btn1:$button1Pressed Btn2:$button2Pressed Btn3:$button3Pressed)");
  }

  void _handleButtonEvent(String key, dynamic value) {
    if (key == "button-0") {
      button0Pressed = value > 0.5;
    }
    else if (key == "button-1") {
      button1Pressed = value > 0.5;
    }
    else if (key == "button-2") {
      button2Pressed = value > 0.5;
    }
    else if (key == "button-3") {
      button3Pressed = value > 0.5;
    }
    else if (key == "button-4") {
      bool isPressed = value > 0.5;
      if (isPressed != button4Pressed) {
        button4Pressed = isPressed;
        _lastActuatorEvent = "Button 4 ${isPressed ? 'DOWN' : 'UP'}";
        _sendActuatorEvent(isPressed ? "DOWN" : "UP", "102");
      }
    }
    else if (key == "button-5") {
      bool isPressed = value > 0.5;
      if (isPressed != button5Pressed) {
        button5Pressed = isPressed;
        _lastActuatorEvent = "Button 5 ${isPressed ? 'DOWN' : 'UP'}";
        _sendActuatorEvent(isPressed ? "DOWN" : "UP", "103");
      }
    }
    else if (key == "dwzpos") {
      double oldDwzPos = dwzPos;
      dwzPos = value.toDouble();

      // Check for threshold crossings
      bool wasHigh = oldDwzPos >= 65000;
      bool wasLow = oldDwzPos < 3000;
      bool isHigh = dwzPos >= 65000;
      bool isLow = dwzPos < 3000;

      if (!wasHigh && isHigh) {
        _lastActuatorEvent = "Z-Axis HIGH -> 104";
        _sendActuatorEvent("DOWN", "104");
      } else if (wasHigh && !isHigh) {
        _lastActuatorEvent = "Z-Axis UP from HIGH -> 104";
        _sendActuatorEvent("UP", "104");
      } else if (!wasLow && isLow) {
        _lastActuatorEvent = "Z-Axis LOW -> 105";
        _sendActuatorEvent("DOWN", "105");
      } else if (wasLow && !isLow) {
        _lastActuatorEvent = "Z-Axis UP from LOW -> 105";
        _sendActuatorEvent("UP", "105");
      }
    }
  }

  // Method to send actuator data via FastDDS
  Future<void> _sendActuatorDataViaFastDDS(String actuatorChar) async {
    if (_publisherTimer != null) {
      try {
        await _channel.invokeMethod('SentMsg', actuatorChar);
        debugPrint('Sent actuator via FastDDS: $actuatorChar');
      } on PlatformException catch (e) {
        debugPrint('sendActuatorData error: $e');
      }
    }
  }

  void _sendActuatorEvent(String eventType, String eventCode) {
    String eventData = "gamepad -> $eventCode";
    print("Sending actuator event: $eventType - $eventData");
  }

  Future<void> _setupGamepad() async {
    final gamepads = await Gamepads.list();
    setState(() {
      _connectedGamepads = gamepads;
    });

    Gamepads.events.listen((event) {
      final key = event.key.toLowerCase();
      final value = event.value;

      _seenKeys.add(key);

      // Mapping inputs
      if (key == "dwxpos") {
        xL = _normalizeAxis(value); // Left Stick X
      } else if (key == "dwrpos") {
        yR = _normalizeAxis(value); // Right Stick Y
      } else if (key == "pov") {
        xH = value.toInt();
        print("POV Hat changed to: $xH");
      } else if (key.startsWith("button-") || key == "dwzpos") {
        _handleButtonEvent(key, value);
      } else {
        _lastKeyEvent = "Other Key: $key → value=$value";
      }

      // Update motorData and send via FastDDS
      _updateMotorData();

      setState(() {
        _log = '''
FastDDS Status: ${_publisherTimer != null ? 'ACTIVE' : 'INACTIVE'}
Current Message: $_currentMessage

Raw:
  dwXpos = ${event.key == "dwxpos" ? value : (xL * 32768 + 32768).toInt()}
  dwRpos = ${event.key == "dwrpos" ? value : (yR * 32768 + 32768).toInt()}
  dwZpos = ${dwzPos.toInt()}
  POV    = $xH

Normalized:
  xL = $xL
  yR = $yR
  xH = $xH

Motor Data = $motorData

Button States:
  Button 0: ${button0Pressed ? 'PRESSED' : 'RELEASED'}
  Button 1: ${button1Pressed ? 'PRESSED' : 'RELEASED'}
  Button 2: ${button2Pressed ? 'PRESSED' : 'RELEASED'}
  Button 3: ${button3Pressed ? 'PRESSED' : 'RELEASED'}
  Button 4: ${button4Pressed ? 'PRESSED' : 'RELEASED'}
  Button 5: ${button5Pressed ? 'PRESSED' : 'RELEASED'}
  Z-Axis: ${dwzPos.toInt()} ${dwzPos >= 65000 ? '(HIGH)' : dwzPos < 3000 ? '(LOW)' : '(MID)'}

$_lastKeyEvent
$_lastActuatorEvent
''';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ASUS ROG Gamepad with FastDDS")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FastDDS Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "FastDDS Controls",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
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
                          ElevatedButton(
                            onPressed: _stopPublisher,
                            child: const Text('Stop Publisher'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Status: ${_publisherTimer != null ? 'Publishing' : 'Stopped'}",
                        style: TextStyle(
                          color: _publisherTimer != null ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Current Message: $_currentMessage"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gamepad Info
              const Text("Connected Gamepads:"),
              ..._connectedGamepads
                  .map((g) => Text('• ${g.name} (id: ${g.id})')),
              const SizedBox(height: 20),

              Text(
                _log,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 30),

              ExpansionTile(
                title: const Text("Detected Raw Keys"),
                children: _seenKeys.map((key) {
                  return ListTile(
                    title: Text('Key: $key'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Manual reset button for testing
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    xH = -1; // Reset POV to neutral
                    _updateMotorData();
                  });
                },
                child: const Text("Reset POV Hat (Debug)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
