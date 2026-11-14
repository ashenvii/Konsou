#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <windowsx.h>

#include <cmath>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

FlutterWindow* g_window = nullptr;
WNDPROC g_view_proc = nullptr;

// The Flutter view covers the whole window, so Windows never asks the window
// itself about the maximize button. Over the button the view says it is not
// there, and the question goes on to the window.
LRESULT CALLBACK ViewProc(HWND view, UINT message, WPARAM wparam,
                          LPARAM lparam) {
  if (message == WM_NCHITTEST && g_window &&
      g_window->IsOverMaximizeButton(GET_X_LPARAM(lparam),
                                     GET_Y_LPARAM(lparam))) {
    return HTTRANSPARENT;
  }
  return CallWindowProc(g_view_proc, view, message, wparam, lparam);
}

double ReadNumber(const flutter::EncodableMap& map, const char* key) {
  auto found = map.find(flutter::EncodableValue(key));
  if (found == map.end()) {
    return 0;
  }
  if (auto number = std::get_if<double>(&found->second)) {
    return *number;
  }
  return 0;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

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

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "konsou/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto* place =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (call.method_name() != "setMaximizeButton" || !place) {
          result->NotImplemented();
          return;
        }
        button_width_ = ReadNumber(*place, "width");
        button_height_ = ReadNumber(*place, "height");
        button_right_inset_ = ReadNumber(*place, "rightInset");
        resize_edge_ = ReadNumber(*place, "resizeEdge");
        result->Success();
      });

  HWND view = flutter_controller_->view()->GetNativeWindow();
  SetChildContent(view);
  g_window = this;
  g_view_proc = reinterpret_cast<WNDPROC>(SetWindowLongPtr(
      view, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(ViewProc)));

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  g_window = nullptr;
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LONG FlutterWindow::ToPixels(double logical) {
  return std::lround(logical * GetDpiForWindow(GetHandle()) / 96.0);
}

bool FlutterWindow::IsOverMaximizeButton(int screen_x, int screen_y) {
  HWND window = GetHandle();
  if (button_width_ <= 0 || !window) {
    return false;
  }
  POINT point = {screen_x, screen_y};
  ScreenToClient(window, &point);
  RECT client = GetClientArea();
  LONG right = client.right - ToPixels(button_right_inset_);
  LONG left = right - ToPixels(button_width_);
  return point.x >= left && point.x < right && point.y >= 0 &&
         point.y < ToPixels(button_height_);
}

void FlutterWindow::SetButtonState(ButtonState state) {
  if (state == button_state_) {
    return;
  }
  button_state_ = state;
  if (window_channel_) {
    window_channel_->InvokeMethod(
        "maximizeButtonState",
        std::make_unique<flutter::EncodableValue>(static_cast<int>(state)));
  }
}

std::optional<LRESULT> FlutterWindow::HandleMaximizeButton(HWND window,
                                                           UINT message,
                                                           WPARAM wparam,
                                                           LPARAM lparam) {
  switch (message) {
    case WM_NCHITTEST: {
      int x = GET_X_LPARAM(lparam);
      int y = GET_Y_LPARAM(lparam);
      if (!IsOverMaximizeButton(x, y)) {
        return std::nullopt;
      }
      // The top edge still resizes, as it does over the other buttons.
      POINT point = {x, y};
      ScreenToClient(window, &point);
      if (!IsZoomed(window) && point.y < ToPixels(resize_edge_)) {
        return HTTOP;
      }
      return HTMAXBUTTON;
    }
    case WM_NCMOUSEMOVE:
      if (wparam == HTMAXBUTTON) {
        if (button_state_ == ButtonState::kNone) {
          SetButtonState(ButtonState::kHovered);
        }
        TRACKMOUSEEVENT track = {sizeof(track), TME_LEAVE | TME_NONCLIENT,
                                 window, 0};
        TrackMouseEvent(&track);
      } else {
        SetButtonState(ButtonState::kNone);
      }
      return std::nullopt;
    case WM_NCMOUSELEAVE:
      SetButtonState(ButtonState::kNone);
      return std::nullopt;
    // Handled here and not passed on: Windows would draw its own old button.
    case WM_NCLBUTTONDOWN:
    case WM_NCLBUTTONDBLCLK:
      if (wparam != HTMAXBUTTON) {
        return std::nullopt;
      }
      SetButtonState(ButtonState::kPressed);
      return 0;
    case WM_NCLBUTTONUP:
      if (wparam != HTMAXBUTTON) {
        return std::nullopt;
      }
      if (button_state_ == ButtonState::kPressed) {
        // The button moves away with the window, so it is no longer hovered.
        SetButtonState(ButtonState::kNone);
        PostMessage(window, WM_SYSCOMMAND,
                    IsZoomed(window) ? SC_RESTORE : SC_MAXIMIZE, 0);
      }
      return 0;
  }
  return std::nullopt;
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (std::optional<LRESULT> result =
          HandleMaximizeButton(hwnd, message, wparam, lparam)) {
    return *result;
  }

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
