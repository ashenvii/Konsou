#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <optional>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  // Whether a point on the screen is on the maximize button Flutter draws.
  bool IsOverMaximizeButton(int screen_x, int screen_y);

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  enum class ButtonState { kNone = 0, kHovered = 1, kPressed = 2 };

  // Answers Windows for the maximize button, so it shows Snap Layouts over
  // it. Nothing is returned for messages that are not about the button.
  std::optional<LRESULT> HandleMaximizeButton(HWND window, UINT message,
                                              WPARAM wparam, LPARAM lparam);

  // Tells Flutter how to draw the button: plain, hovered or pressed.
  void SetButtonState(ButtonState state);

  // A length in Flutter's logical pixels as pixels of this window.
  LONG ToPixels(double logical);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_channel_;

  // The maximize button's place, in logical pixels, sent by Flutter. A width
  // of zero means Flutter has not sent it.
  double button_width_ = 0;
  double button_height_ = 0;
  double button_right_inset_ = 0;
  double resize_edge_ = 0;

  ButtonState button_state_ = ButtonState::kNone;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
