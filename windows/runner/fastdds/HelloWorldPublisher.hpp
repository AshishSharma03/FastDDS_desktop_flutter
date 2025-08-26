#pragma once
#include <string>
// Exposed function for Flutter
void run_publisher();
void on_flutter_message(const std::string& msg);
void stop_publisher();