import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:ffi/ffi.dart';

import 'placement.dart';

final class _Point extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
}

final class _Rect extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

/// WINDOWPLACEMENT from the Win32 API.
final class _Placement extends Struct {
  @Uint32()
  external int length;
  @Uint32()
  external int flags;
  @Uint32()
  external int showCmd;
  external _Point minPosition;
  external _Point maxPosition;
  external _Rect normalPosition;
}

final class _MonitorInfo extends Struct {
  @Uint32()
  external int size;
  external _Rect monitor;
  external _Rect work;
  @Uint32()
  external int flags;
}

const _nearestMonitor = 2;
const _primaryMonitor = 1;
const _runnerClass = 'FLUTTER_RUNNER_WIN32_WINDOW';
const _hidden = 0;
const _styleIndex = -16;
const _maximizeStyle = 0x01000000;

/// Gives the still hidden window its saved placement, the way Windows does:
/// [normal] is the size and position it has when not maximized, and it is
/// moved onto a connected screen if the saved spot is off screen. When
/// [maximized] is true the window is marked maximized, so the runner shows it
/// maximized on its first frame. Nothing is shown here, so nothing flashes.
///
/// [normal] is in logical pixels, [scale] is the device pixel ratio. Saved
/// positions from a screen with a different scale than the primary one are not
/// handled yet.
/// Returns false when this process's window could not be found.
bool restoreWindowPlacement({
  required String title,
  required Rect normal,
  required double scale,
  required bool maximized,
}) {
  if (!Platform.isWindows) return false;
  final user32 = DynamicLibrary.open('user32.dll');
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final findWindowEx = user32
      .lookupFunction<
        IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>),
        int Function(int, int, Pointer<Utf16>, Pointer<Utf16>)
      >('FindWindowExW');
  final windowProcess = user32
      .lookupFunction<
        Uint32 Function(IntPtr, Pointer<Uint32>),
        int Function(int, Pointer<Uint32>)
      >('GetWindowThreadProcessId');
  final currentProcess = kernel32
      .lookupFunction<Uint32 Function(), int Function()>('GetCurrentProcessId');
  final setPlacement = user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<_Placement>),
        int Function(int, Pointer<_Placement>)
      >('SetWindowPlacement');
  final getStyle = user32
      .lookupFunction<IntPtr Function(IntPtr, Int32), int Function(int, int)>(
        'GetWindowLongPtrW',
      );
  final setStyle = user32
      .lookupFunction<
        IntPtr Function(IntPtr, Int32, IntPtr),
        int Function(int, int, int)
      >('SetWindowLongPtrW');
  final monitorFromPoint = user32
      .lookupFunction<
        IntPtr Function(_Point, Uint32),
        int Function(_Point, int)
      >('MonitorFromPoint');
  final monitorFromRect = user32
      .lookupFunction<
        IntPtr Function(Pointer<_Rect>, Uint32),
        int Function(Pointer<_Rect>, int)
      >('MonitorFromRect');
  final getMonitorInfo = user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<_MonitorInfo>),
        int Function(int, Pointer<_MonitorInfo>)
      >('GetMonitorInfoW');

  final cls = _runnerClass.toNativeUtf16();
  final name = title.toNativeUtf16();
  final pid = calloc<Uint32>();
  final placement = calloc<_Placement>();
  final primary = calloc<_MonitorInfo>();
  final target = calloc<_MonitorInfo>();
  final want = calloc<_Rect>();
  final origin = calloc<_Point>();
  try {
    // Only this process's window: another Konsou must never be touched.
    var hwnd = 0;
    while (true) {
      hwnd = findWindowEx(0, hwnd, cls, name);
      if (hwnd == 0) return false;
      windowProcess(hwnd, pid);
      if (pid.value == currentProcess()) break;
    }

    // Placement coordinates start at the primary monitor's work area, not at
    // the screen corner, so a taskbar or dock on the top or left shifts them.
    primary.ref.size = sizeOf<_MonitorInfo>();
    var shiftX = 0;
    var shiftY = 0;
    if (getMonitorInfo(
          monitorFromPoint(origin.ref, _primaryMonitor),
          primary,
        ) !=
        0) {
      shiftX = primary.ref.work.left - primary.ref.monitor.left;
      shiftY = primary.ref.work.top - primary.ref.monitor.top;
    }

    // Where the window wants to be, in screen pixels, moved onto the nearest
    // monitor if it is off screen.
    var fitted = PixelRect(
      (normal.left * scale).round(),
      (normal.top * scale).round(),
      (normal.right * scale).round(),
      (normal.bottom * scale).round(),
    );
    want.ref
      ..left = fitted.left
      ..top = fitted.top
      ..right = fitted.right
      ..bottom = fitted.bottom;
    target.ref.size = sizeOf<_MonitorInfo>();
    if (getMonitorInfo(monitorFromRect(want, _nearestMonitor), target) != 0) {
      final work = target.ref.work;
      fitted = fitIntoWorkArea(
        fitted,
        PixelRect(work.left, work.top, work.right, work.bottom),
      );
    }

    placement.ref
      ..length = sizeOf<_Placement>()
      ..showCmd = _hidden;
    placement.ref.normalPosition
      ..left = fitted.left - shiftX
      ..top = fitted.top - shiftY
      ..right = fitted.right - shiftX
      ..bottom = fitted.bottom - shiftY;
    if (setPlacement(hwnd, placement) == 0) return false;
    if (maximized) {
      setStyle(hwnd, _styleIndex, getStyle(hwnd, _styleIndex) | _maximizeStyle);
    }
    return true;
  } finally {
    calloc.free(cls);
    calloc.free(name);
    calloc.free(pid);
    calloc.free(placement);
    calloc.free(primary);
    calloc.free(target);
    calloc.free(want);
    calloc.free(origin);
  }
}
