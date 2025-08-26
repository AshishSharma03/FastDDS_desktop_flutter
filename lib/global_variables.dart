

import 'package:flutter/material.dart';

String robotIP = '192.168.68.115';
var data = '', motor = '', actuator = '', power = '';
String motorData = '0', actuatorData = '0', powerData = 's';
double globalSignalStrength = 0.0;
String? password = 'admin';
double stickRadius = 0.25;
String controlSend = '0';
bool isOpen = false;

bool ndsAlter = false;
bool powerAlter = false;
bool boolSwitcher = false;
bool turnAlter = false;
bool controlAlter = true;
bool emergencyAlter = true;
bool wifiAlter = true;
String robotId = '', dataSignal = '';
bool isSwitched = false;
double currentPosition = 80.0;
double positionEmergency = 80.0;
double positionCharge = 120.0;
double statePosition = 80.0;
double actualPosition = -255.0;
double shovelPosition = 50;
var vall = '';
double pitch = 0.0;
double roll = 0.0;
bool onTapVisible = false;
double signalStrength = 0.0;
// String wifiValue = '';

bool open = false;
var permissionState = 0;
int val = 0;
bool light = true;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


List<String> availableSSIDs = [];

///
bool showTextField = false;
bool showButtons = false;
const String predefinedPassword = "1234";

bool isFirstDrawer = true;
bool showAndroidView = false;
String displayedText = "";


List<Color> colors = [Colors.red, Colors.orange, Colors.yellow, Colors.white];
