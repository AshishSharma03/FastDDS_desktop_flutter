#include "flutter_window.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <optional>
#include <thread>  // <-- Add this
#include <iostream> // optional if using std::cout
#include "flutter/generated_plugin_registrant.h"
#include "fastdds/HelloWorldPublisher.hpp"
#include "fastdds/HelloWorldSubscriber.hpp"
#include <string>
#include <fstream>
FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }
    // --- Allocate a console so std::cout works in the .exe ---
    AllocConsole();
    FILE* fDummy;
    freopen_s(&fDummy, "CONOUT$", "w", stdout);
    freopen_s(&fDummy, "CONOUT$", "w", stderr);
    std::cout << "Console attached for logging" << std::endl;
    // ---------------------------------------------------------

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  static int counter_value = 0;

    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            flutter_controller_->engine()->messenger(),
                    "counter_channel",
                    &flutter::StandardMethodCodec::GetInstance());

    channel->SetMethodCallHandler(
            [](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

                if (call.method_name() == "startPublisher") {
                    std::thread(run_publisher).detach();
                    result->Success(flutter::EncodableValue(true));
                    return;
                }

                if (call.method_name() == "SentMsg") {
                    if (call.arguments()) {
                        const flutter::EncodableValue& args = *call.arguments();
                        if (const std::string* msg = std::get_if<std::string>(&args)) {
                            std::string message_copy = *msg; // copy here
                            // Run in a separate thread to avoid blocking Flutter
                            std::thread([message_copy]() {
//                                std::cout << "[FlutterWindow] Received message from Flutter: " << message_copy << std::endl;
                                on_flutter_message(message_copy);
                            }).detach();
                            result->Success(flutter::EncodableValue(true));
                        } else {
                            result->Error("Invalid argument", "Expected a string");
                        }
                    } else {
                        result->Error("No argument", "Expected a string argument");
                    }
                    return;
                }

                if(call.method_name() == "stopPublisher"){
                    std::thread(stop_publisher).detach();
                    result->Success(flutter::EncodableValue(true));
                    return;
                }

                if (call.method_name() == "startSubscriber") {
                    std::thread(run_subscriber).detach();
                    result->Success(flutter::EncodableValue(true));
                    return;
                }


                if(call.method_name() == "stopPublisher"){
                    std::thread(stop_publisher).detach();
                    result->Success(flutter::EncodableValue(true));
                    return;
                }

                result->NotImplemented();
            });

    // Keep the channel alive for the lifetime of the window
    // (store it as a member if you want to persist it across calls)
    counter_channel_ = std::move(channel);
    // -------------------------

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
