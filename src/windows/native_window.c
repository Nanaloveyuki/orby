#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellscalingapi.h>
#include <moonbit.h>
#include <stdint.h>

typedef void (*orby_event_callback)(void *, int32_t, int32_t, int32_t, int32_t, double, double);

static const wchar_t *ORBY_CLASS = L"OrbyWindow";
static orby_event_callback event_callback = NULL;
static void *event_context = NULL;
static int initialized_com = 0;
static int32_t window_count = 0;
static int exit_requested = 0;
static int32_t exit_code = 0;
static int poll_mode = 0;
static HWND tracked_mouse_window = NULL;
static uint16_t pending_high_surrogate = 0;

typedef struct OrbySizeConstraints {
  HWND hwnd;
  int32_t min_width;
  int32_t min_height;
  int32_t max_width;
  int32_t max_height;
  int fullscreen;
  LONG_PTR saved_style;
  LONG_PTR saved_ex_style;
  RECT saved_rect;
  struct OrbySizeConstraints *next;
} OrbySizeConstraints;

static OrbySizeConstraints *size_constraints = NULL;

static void client_to_outer_rect(DWORD style, DWORD ex_style, int32_t width, int32_t height, RECT *rect) {
  rect->left = 0;
  rect->top = 0;
  rect->right = width > 0 ? width : 1;
  rect->bottom = height > 0 ? height : 1;
  AdjustWindowRectEx(rect, style, FALSE, ex_style);
}

static HMONITOR primary_monitor(void) {
  POINT origin = { 0, 0 };
  return MonitorFromPoint(origin, MONITOR_DEFAULTTOPRIMARY);
}

static int32_t monitor_metric(HMONITOR monitor, int32_t metric) {
  MONITORINFO info = { sizeof(info) };
  if (monitor == NULL || !GetMonitorInfoW(monitor, &info)) return 0;
  RECT rect = metric < 4 ? info.rcMonitor : info.rcWork;
  switch (metric % 4) {
  case 0: return rect.left;
  case 1: return rect.top;
  case 2: return rect.right - rect.left;
  default: return rect.bottom - rect.top;
  }
}

static double monitor_scale(HMONITOR monitor) {
  typedef HRESULT (WINAPI *get_dpi_for_monitor_fn)(HMONITOR, int, UINT *, UINT *);
  HMODULE shcore = LoadLibraryW(L"shcore.dll");
  get_dpi_for_monitor_fn get_dpi = shcore == NULL ? NULL :
      (get_dpi_for_monitor_fn)GetProcAddress(shcore, "GetDpiForMonitor");
  UINT dpi_x = 0, dpi_y = 0;
  HRESULT result = get_dpi == NULL ? E_FAIL : get_dpi(monitor, 0, &dpi_x, &dpi_y);
  if (shcore != NULL) FreeLibrary(shcore);
  return SUCCEEDED(result) && dpi_x != 0 ? (double)dpi_x / 96.0 : (double)GetDpiForSystem() / 96.0;
}

static OrbySizeConstraints *constraints_for(HWND hwnd, int create) {
  OrbySizeConstraints *current = size_constraints;
  while (current != NULL) {
    if (current->hwnd == hwnd) return current;
    current = current->next;
  }
  if (!create) return NULL;
  current = (OrbySizeConstraints *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof(*current));
  if (current == NULL) return NULL;
  current->hwnd = hwnd;
  current->next = size_constraints;
  size_constraints = current;
  return current;
}

static void remove_constraints(HWND hwnd) {
  OrbySizeConstraints **current = &size_constraints;
  while (*current != NULL) {
    if ((*current)->hwnd == hwnd) {
      OrbySizeConstraints *removed = *current;
      *current = removed->next;
      HeapFree(GetProcessHeap(), 0, removed);
      return;
    }
    current = &(*current)->next;
  }
}

static int32_t constrained_dimension(int32_t value, int32_t minimum, int32_t maximum) {
  if (value < 1) value = 1;
  if (minimum > 0 && value < minimum) value = minimum;
  if (maximum > 0 && value > maximum) value = maximum;
  return value;
}

static void apply_size_constraints(HWND hwnd, MINMAXINFO *info) {
  OrbySizeConstraints *constraints = constraints_for(hwnd, 0);
  if (constraints == NULL) return;
  DWORD style = (DWORD)GetWindowLongPtrW(hwnd, GWL_STYLE);
  DWORD ex_style = (DWORD)GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  RECT rect;
  if (constraints->min_width > 0 || constraints->min_height > 0) {
    client_to_outer_rect(style, ex_style,
        constraints->min_width > 0 ? constraints->min_width : 1,
        constraints->min_height > 0 ? constraints->min_height : 1, &rect);
    if (constraints->min_width > 0) info->ptMinTrackSize.x = rect.right - rect.left;
    if (constraints->min_height > 0) info->ptMinTrackSize.y = rect.bottom - rect.top;
  }
  if (constraints->max_width > 0 || constraints->max_height > 0) {
    client_to_outer_rect(style, ex_style,
        constraints->max_width > 0 ? constraints->max_width : 1,
        constraints->max_height > 0 ? constraints->max_height : 1, &rect);
    if (constraints->max_width > 0) info->ptMaxTrackSize.x = rect.right - rect.left;
    if (constraints->max_height > 0) info->ptMaxTrackSize.y = rect.bottom - rect.top;
  }
}

static void emit_event(HWND hwnd, int32_t kind, int32_t arg0, int32_t arg1, double argd0, double argd1) {
  if (event_callback == NULL) return;
  const int32_t id = (int32_t)(intptr_t)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
  if (id > 0) event_callback(event_context, kind, id, arg0, arg1, argd0, argd1);
}

static void emit_application_event(int32_t kind) {
  if (event_callback != NULL) event_callback(event_context, kind, 0, 0, 0, 0.0, 0.0);
}

static int32_t current_modifiers(void) {
  int32_t modifiers = 0;
  if (GetKeyState(VK_SHIFT) < 0) modifiers |= 1;
  if (GetKeyState(VK_CONTROL) < 0) modifiers |= 2;
  if (GetKeyState(VK_MENU) < 0) modifiers |= 4;
  if (GetKeyState(VK_LWIN) < 0 || GetKeyState(VK_RWIN) < 0) modifiers |= 8;
  return modifiers;
}

static void emit_text(HWND hwnd, uint32_t codepoint) {
  if (codepoint >= 0x20 && codepoint != 0x7F && codepoint <= 0x10FFFF) {
    emit_event(hwnd, 8, (int32_t)codepoint, 0, 0.0, 0.0);
  }
}

static void emit_utf16_text(HWND hwnd, uint16_t unit) {
  if (unit >= 0xD800 && unit <= 0xDBFF) {
    pending_high_surrogate = unit;
    return;
  }
  if (unit >= 0xDC00 && unit <= 0xDFFF && pending_high_surrogate != 0) {
    uint32_t codepoint = 0x10000 + (((uint32_t)pending_high_surrogate - 0xD800) << 10) + (unit - 0xDC00);
    pending_high_surrogate = 0;
    emit_text(hwnd, codepoint);
    return;
  }
  pending_high_surrogate = 0;
  if (unit < 0xD800 || unit > 0xDFFF) emit_text(hwnd, unit);
}

static LRESULT CALLBACK orby_wndproc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  switch (message) {
  case WM_GETMINMAXINFO:
    apply_size_constraints(hwnd, (MINMAXINFO *)lparam);
    return 0;
  case WM_CLOSE:
    emit_event(hwnd, 1, 0, 0, 0.0, 0.0);
    return 0;
  case WM_DESTROY:
    if (window_count > 0) window_count--;
    if (tracked_mouse_window == hwnd) tracked_mouse_window = NULL;
    emit_event(hwnd, 2, 0, 0, 0.0, 0.0);
    if (window_count == 0 && !exit_requested) PostQuitMessage(0);
    return 0;
  case WM_NCDESTROY:
    remove_constraints(hwnd);
    return DefWindowProcW(hwnd, message, wparam, lparam);
  case WM_SIZE:
    emit_event(hwnd, 3, LOWORD(lparam), HIWORD(lparam), 0.0, 0.0);
    return 0;
  case WM_DPICHANGED:
    emit_event(hwnd, 4, 0, 0, (double)HIWORD(wparam) / 96.0, 0.0);
    return 0;
  case WM_SETFOCUS:
    emit_event(hwnd, 5, 1, 0, 0.0, 0.0);
    return 0;
  case WM_KILLFOCUS:
    emit_event(hwnd, 5, 0, 0, 0.0, 0.0);
    return 0;
  case WM_PAINT: {
    PAINTSTRUCT paint;
    BeginPaint(hwnd, &paint);
    EndPaint(hwnd, &paint);
    emit_event(hwnd, 6, 0, 0, 0.0, 0.0);
    return 0;
  }
  case WM_KEYDOWN:
  case WM_SYSKEYDOWN: {
    int32_t flags = current_modifiers() | 16;
    if ((lparam & 0x40000000) != 0) flags |= 32;
    emit_event(hwnd, 7, (int32_t)wparam, flags, 0.0, 0.0);
    return 0;
  }
  case WM_KEYUP:
  case WM_SYSKEYUP:
    emit_event(hwnd, 7, (int32_t)wparam, current_modifiers(), 0.0, 0.0);
    return 0;
  case WM_CHAR:
    emit_utf16_text(hwnd, (uint16_t)wparam);
    return 0;
  case WM_UNICHAR:
    if (wparam == UNICODE_NOCHAR) return TRUE;
    emit_text(hwnd, (uint32_t)wparam);
    return 0;
  case WM_MOUSEMOVE: {
    if (tracked_mouse_window != hwnd) {
      if (tracked_mouse_window != NULL) emit_event(tracked_mouse_window, 11, 0, 0, 0.0, 0.0);
      tracked_mouse_window = hwnd;
      TRACKMOUSEEVENT tracking = { sizeof(tracking), TME_LEAVE, hwnd, 0 };
      TrackMouseEvent(&tracking);
      emit_event(hwnd, 10, 0, 0, 0.0, 0.0);
    }
    emit_event(hwnd, 9, (int16_t)LOWORD(lparam), (int16_t)HIWORD(lparam), 0.0, 0.0);
    return 0;
  }
  case WM_MOUSELEAVE:
    if (tracked_mouse_window == hwnd) tracked_mouse_window = NULL;
    emit_event(hwnd, 11, 0, 0, 0.0, 0.0);
    return 0;
  case WM_LBUTTONDOWN:
  case WM_LBUTTONUP:
  case WM_RBUTTONDOWN:
  case WM_RBUTTONUP:
  case WM_MBUTTONDOWN:
  case WM_MBUTTONUP:
  case WM_XBUTTONDOWN:
  case WM_XBUTTONUP: {
    int32_t button = 1;
    if (message == WM_RBUTTONDOWN || message == WM_RBUTTONUP) button = 2;
    else if (message == WM_MBUTTONDOWN || message == WM_MBUTTONUP) button = 3;
    else if (message == WM_XBUTTONDOWN || message == WM_XBUTTONUP) button = HIWORD(wparam) == XBUTTON1 ? 4 : 5;
    int32_t pressed = message == WM_LBUTTONDOWN || message == WM_RBUTTONDOWN ||
        message == WM_MBUTTONDOWN || message == WM_XBUTTONDOWN;
    emit_event(hwnd, 12, button, current_modifiers() | (pressed ? 16 : 0), 0.0, 0.0);
    return 0;
  }
  case WM_MOUSEWHEEL:
    emit_event(hwnd, 13, 0, current_modifiers(), 0.0, -(double)(int16_t)HIWORD(wparam) / WHEEL_DELTA);
    return 0;
  case WM_MOUSEHWHEEL:
    emit_event(hwnd, 13, 0, current_modifiers(), (double)(int16_t)HIWORD(wparam) / WHEEL_DELTA, 0.0);
    return 0;
  default:
    return DefWindowProcW(hwnd, message, wparam, lparam);
  }
}

MOONBIT_FFI_EXPORT int32_t orby_win_init(void) {
  HRESULT result = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
  if (result == S_OK || result == S_FALSE) initialized_com = 1;
  else if (result == RPC_E_CHANGED_MODE) return 0;
  window_count = 0;
  exit_requested = 0;
  exit_code = 0;
  poll_mode = 0;
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  WNDCLASSEXW wc = {0};
  wc.cbSize = sizeof(wc);
  wc.hInstance = GetModuleHandleW(NULL);
  wc.hCursor = LoadCursorW(NULL, MAKEINTRESOURCEW(32512));
  wc.lpfnWndProc = orby_wndproc;
  wc.lpszClassName = ORBY_CLASS;
  return RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
}

MOONBIT_FFI_EXPORT uint64_t orby_win_create_window(
    moonbit_bytes_t title, int32_t width, int32_t height, int32_t visible,
    int32_t resizable, int32_t id) {
  int wide_len = MultiByteToWideChar(CP_UTF8, 0, (const char *)title, -1, NULL, 0);
  if (wide_len <= 0) return 0;
  wchar_t *wide = (wchar_t *)HeapAlloc(GetProcessHeap(), 0, wide_len * sizeof(wchar_t));
  if (wide == NULL) return 0;
  MultiByteToWideChar(CP_UTF8, 0, (const char *)title, -1, wide, wide_len);
  DWORD style = WS_OVERLAPPEDWINDOW;
  if (!resizable) style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  RECT rect;
  client_to_outer_rect(style, 0, width, height, &rect);
  HWND hwnd = CreateWindowExW(0, ORBY_CLASS, wide, style, CW_USEDEFAULT, CW_USEDEFAULT,
      rect.right - rect.left, rect.bottom - rect.top, NULL, NULL, GetModuleHandleW(NULL), NULL);
  HeapFree(GetProcessHeap(), 0, wide);
  if (hwnd == NULL) return 0;
  SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)id);
  window_count++;
  if (visible) ShowWindow(hwnd, SW_SHOW);
  return (uint64_t)(uintptr_t)hwnd;
}

MOONBIT_FFI_EXPORT void orby_win_destroy_window(uint64_t hwnd) { DestroyWindow((HWND)(uintptr_t)hwnd); }
MOONBIT_FFI_EXPORT void orby_win_set_title(uint64_t hwnd, moonbit_bytes_t title) {
  int wide_len = MultiByteToWideChar(CP_UTF8, 0, (const char *)title, -1, NULL, 0);
  if (wide_len <= 0) return;
  wchar_t *wide = (wchar_t *)HeapAlloc(GetProcessHeap(), 0, wide_len * sizeof(wchar_t));
  if (wide == NULL) return;
  MultiByteToWideChar(CP_UTF8, 0, (const char *)title, -1, wide, wide_len);
  SetWindowTextW((HWND)(uintptr_t)hwnd, wide);
  HeapFree(GetProcessHeap(), 0, wide);
}
MOONBIT_FFI_EXPORT void orby_win_request_redraw(uint64_t hwnd) { InvalidateRect((HWND)(uintptr_t)hwnd, NULL, FALSE); }
MOONBIT_FFI_EXPORT void orby_win_set_visible(uint64_t hwnd, int32_t visible) {
  ShowWindow((HWND)(uintptr_t)hwnd, visible ? SW_SHOW : SW_HIDE);
}
MOONBIT_FFI_EXPORT void orby_win_set_resizable(uint64_t hwnd, int32_t resizable) {
  HWND window = (HWND)(uintptr_t)hwnd;
  LONG_PTR style = GetWindowLongPtrW(window, GWL_STYLE);
  if (resizable) style |= WS_THICKFRAME | WS_MAXIMIZEBOX;
  else style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  SetWindowLongPtrW(window, GWL_STYLE, style);
  SetWindowPos(window, NULL, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
}
MOONBIT_FFI_EXPORT void orby_win_set_minimized(uint64_t hwnd, int32_t minimized) {
  ShowWindow((HWND)(uintptr_t)hwnd, minimized ? SW_MINIMIZE : SW_RESTORE);
}
MOONBIT_FFI_EXPORT int32_t orby_win_is_minimized(uint64_t hwnd) { return IsIconic((HWND)(uintptr_t)hwnd) != 0; }
MOONBIT_FFI_EXPORT void orby_win_set_maximized(uint64_t hwnd, int32_t maximized) {
  ShowWindow((HWND)(uintptr_t)hwnd, maximized ? SW_MAXIMIZE : SW_RESTORE);
}
MOONBIT_FFI_EXPORT int32_t orby_win_is_maximized(uint64_t hwnd) { return IsZoomed((HWND)(uintptr_t)hwnd) != 0; }
MOONBIT_FFI_EXPORT void orby_win_set_decorated(uint64_t hwnd, int32_t decorated) {
  HWND window = (HWND)(uintptr_t)hwnd;
  LONG_PTR style = GetWindowLongPtrW(window, GWL_STYLE);
  if (decorated) style |= WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
  else style &= ~(WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX);
  SetWindowLongPtrW(window, GWL_STYLE, style);
  SetWindowPos(window, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
}
MOONBIT_FFI_EXPORT void orby_win_set_fullscreen(uint64_t hwnd, int32_t fullscreen) {
  HWND window = (HWND)(uintptr_t)hwnd;
  OrbySizeConstraints *state = constraints_for(window, fullscreen != 0);
  if (state == NULL || (state->fullscreen != 0) == (fullscreen != 0)) return;
  if (fullscreen) {
    MONITORINFO monitor = { sizeof(monitor) };
    HMONITOR target = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
    if (target == NULL || !GetMonitorInfoW(target, &monitor)) return;
    state->saved_style = GetWindowLongPtrW(window, GWL_STYLE);
    state->saved_ex_style = GetWindowLongPtrW(window, GWL_EXSTYLE);
    if (!GetWindowRect(window, &state->saved_rect)) return;
    SetWindowLongPtrW(window, GWL_STYLE, state->saved_style & ~WS_OVERLAPPEDWINDOW);
    SetWindowPos(window, HWND_TOP, monitor.rcMonitor.left, monitor.rcMonitor.top,
        monitor.rcMonitor.right - monitor.rcMonitor.left,
        monitor.rcMonitor.bottom - monitor.rcMonitor.top,
        SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    state->fullscreen = 1;
  } else {
    SetWindowLongPtrW(window, GWL_STYLE, state->saved_style);
    SetWindowLongPtrW(window, GWL_EXSTYLE, state->saved_ex_style);
    SetWindowPos(window, NULL, state->saved_rect.left, state->saved_rect.top,
        state->saved_rect.right - state->saved_rect.left,
        state->saved_rect.bottom - state->saved_rect.top,
        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    state->fullscreen = 0;
  }
}
MOONBIT_FFI_EXPORT int32_t orby_win_is_fullscreen(uint64_t hwnd) {
  OrbySizeConstraints *state = constraints_for((HWND)(uintptr_t)hwnd, 0);
  return state != NULL && state->fullscreen != 0;
}
MOONBIT_FFI_EXPORT void orby_win_set_min_inner_size(uint64_t hwnd, int32_t width, int32_t height) {
  OrbySizeConstraints *constraints = constraints_for((HWND)(uintptr_t)hwnd, 1);
  if (constraints == NULL) return;
  constraints->min_width = width > 0 ? width : 0;
  constraints->min_height = height > 0 ? height : 0;
  if (constraints->max_width > 0 && constraints->min_width > constraints->max_width) constraints->max_width = constraints->min_width;
  if (constraints->max_height > 0 && constraints->min_height > constraints->max_height) constraints->max_height = constraints->min_height;
}
MOONBIT_FFI_EXPORT void orby_win_set_max_inner_size(uint64_t hwnd, int32_t width, int32_t height) {
  OrbySizeConstraints *constraints = constraints_for((HWND)(uintptr_t)hwnd, 1);
  if (constraints == NULL) return;
  constraints->max_width = width > 0 ? width : 0;
  constraints->max_height = height > 0 ? height : 0;
  if (constraints->max_width > 0 && constraints->min_width > constraints->max_width) constraints->min_width = constraints->max_width;
  if (constraints->max_height > 0 && constraints->min_height > constraints->max_height) constraints->min_height = constraints->max_height;
}
MOONBIT_FFI_EXPORT void orby_win_set_inner_size(uint64_t hwnd, int32_t width, int32_t height) {
  HWND window = (HWND)(uintptr_t)hwnd;
  OrbySizeConstraints *constraints = constraints_for(window, 0);
  width = constrained_dimension(width,
      constraints == NULL ? 0 : constraints->min_width,
      constraints == NULL ? 0 : constraints->max_width);
  height = constrained_dimension(height,
      constraints == NULL ? 0 : constraints->min_height,
      constraints == NULL ? 0 : constraints->max_height);
  RECT rect;
  client_to_outer_rect(
      (DWORD)GetWindowLongPtrW(window, GWL_STYLE),
      (DWORD)GetWindowLongPtrW(window, GWL_EXSTYLE), width, height, &rect);
  SetWindowPos(window, NULL, 0, 0, rect.right - rect.left, rect.bottom - rect.top,
      SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
}
MOONBIT_FFI_EXPORT int32_t orby_win_inner_width(uint64_t hwnd) {
  RECT rect;
  return GetClientRect((HWND)(uintptr_t)hwnd, &rect) ? rect.right - rect.left : 0;
}
MOONBIT_FFI_EXPORT int32_t orby_win_inner_height(uint64_t hwnd) {
  RECT rect;
  return GetClientRect((HWND)(uintptr_t)hwnd, &rect) ? rect.bottom - rect.top : 0;
}
MOONBIT_FFI_EXPORT double orby_win_scale_factor(uint64_t hwnd) {
  UINT dpi = GetDpiForWindow((HWND)(uintptr_t)hwnd);
  return dpi == 0 ? 1.0 : (double)dpi / 96.0;
}
MOONBIT_FFI_EXPORT void orby_win_set_outer_position(uint64_t hwnd, int32_t x, int32_t y) {
  SetWindowPos((HWND)(uintptr_t)hwnd, NULL, x, y, 0, 0,
      SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}
MOONBIT_FFI_EXPORT void orby_win_request_close(uint64_t hwnd) {
  PostMessageW((HWND)(uintptr_t)hwnd, WM_CLOSE, 0, 0);
}
MOONBIT_FFI_EXPORT void orby_win_exit(int32_t code) {
  exit_requested = 1;
  exit_code = code;
  PostQuitMessage(code);
}
MOONBIT_FFI_EXPORT void orby_win_set_control_flow(int32_t poll) { poll_mode = poll != 0; }
MOONBIT_FFI_EXPORT int32_t orby_win_has_primary_monitor(void) { return primary_monitor() != NULL; }
MOONBIT_FFI_EXPORT int32_t orby_win_primary_monitor_metric(int32_t metric) { return monitor_metric(primary_monitor(), metric); }
MOONBIT_FFI_EXPORT double orby_win_primary_monitor_scale(void) { return monitor_scale(primary_monitor()); }
MOONBIT_FFI_EXPORT int32_t orby_win_has_current_monitor(uint64_t hwnd) {
  return MonitorFromWindow((HWND)(uintptr_t)hwnd, MONITOR_DEFAULTTONULL) != NULL;
}
MOONBIT_FFI_EXPORT int32_t orby_win_current_monitor_metric(uint64_t hwnd, int32_t metric) {
  return monitor_metric(MonitorFromWindow((HWND)(uintptr_t)hwnd, MONITOR_DEFAULTTONULL), metric);
}
MOONBIT_FFI_EXPORT double orby_win_current_monitor_scale(uint64_t hwnd) {
  HWND window = (HWND)(uintptr_t)hwnd;
  UINT dpi = GetDpiForWindow(window);
  return dpi == 0 ? monitor_scale(MonitorFromWindow(window, MONITOR_DEFAULTTONULL)) : (double)dpi / 96.0;
}
MOONBIT_FFI_EXPORT void orby_win_set_event_callback(orby_event_callback callback, void *context) {
  if (event_context != NULL) moonbit_decref(event_context);
  event_callback = callback;
  event_context = context;
}
MOONBIT_FFI_EXPORT int32_t orby_win_run(void) {
  MSG message;
  int32_t code = 0;
  for (;;) {
    while (PeekMessageW(&message, NULL, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        code = (int32_t)message.wParam;
        goto finish;
      }
      TranslateMessage(&message);
      DispatchMessageW(&message);
      if (exit_requested) {
        code = exit_code;
        goto finish;
      }
    }
    emit_application_event(14);
    if (exit_requested) {
      code = exit_code;
      break;
    }
    if (poll_mode) continue;
    int message_result = GetMessageW(&message, NULL, 0, 0);
    if (message_result <= 0) {
      code = message_result == 0 ? (int32_t)message.wParam : 1;
      break;
    }
    TranslateMessage(&message);
    DispatchMessageW(&message);
    if (exit_requested) {
      code = exit_code;
      break;
    }
  }
finish:
  event_callback = NULL;
  if (event_context != NULL) moonbit_decref(event_context);
  event_context = NULL;
  exit_requested = 0;
  exit_code = 0;
  poll_mode = 0;
  if (initialized_com) { CoUninitialize(); initialized_com = 0; }
  return code;
}
#else
#include <moonbit.h>
#include <stdint.h>
MOONBIT_FFI_EXPORT int32_t orby_win_init(void) { return 0; }
MOONBIT_FFI_EXPORT uint64_t orby_win_create_window(moonbit_bytes_t t, int32_t w, int32_t h, int32_t v, int32_t r, int32_t i) { (void)t; (void)w; (void)h; (void)v; (void)r; (void)i; return 0; }
MOONBIT_FFI_EXPORT void orby_win_destroy_window(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_win_set_title(uint64_t h, moonbit_bytes_t t) { (void)h; (void)t; }
MOONBIT_FFI_EXPORT void orby_win_request_redraw(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_win_set_visible(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT void orby_win_set_resizable(uint64_t h, int32_t r) { (void)h; (void)r; }
MOONBIT_FFI_EXPORT void orby_win_set_minimized(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT int32_t orby_win_is_minimized(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT void orby_win_set_maximized(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT int32_t orby_win_is_maximized(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT void orby_win_set_decorated(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT void orby_win_set_fullscreen(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT int32_t orby_win_is_fullscreen(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT void orby_win_set_min_inner_size(uint64_t h, int32_t w, int32_t t) { (void)h; (void)w; (void)t; }
MOONBIT_FFI_EXPORT void orby_win_set_max_inner_size(uint64_t h, int32_t w, int32_t t) { (void)h; (void)w; (void)t; }
MOONBIT_FFI_EXPORT void orby_win_set_inner_size(uint64_t h, int32_t w, int32_t t) { (void)h; (void)w; (void)t; }
MOONBIT_FFI_EXPORT int32_t orby_win_inner_width(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT int32_t orby_win_inner_height(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT double orby_win_scale_factor(uint64_t h) { (void)h; return 1.0; }
MOONBIT_FFI_EXPORT void orby_win_set_outer_position(uint64_t h, int32_t x, int32_t y) { (void)h; (void)x; (void)y; }
MOONBIT_FFI_EXPORT void orby_win_request_close(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_win_exit(int32_t c) { (void)c; }
MOONBIT_FFI_EXPORT void orby_win_set_control_flow(int32_t p) { (void)p; }
MOONBIT_FFI_EXPORT int32_t orby_win_has_primary_monitor(void) { return 0; }
MOONBIT_FFI_EXPORT int32_t orby_win_primary_monitor_metric(int32_t m) { (void)m; return 0; }
MOONBIT_FFI_EXPORT double orby_win_primary_monitor_scale(void) { return 1.0; }
MOONBIT_FFI_EXPORT int32_t orby_win_has_current_monitor(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT int32_t orby_win_current_monitor_metric(uint64_t h, int32_t m) { (void)h; (void)m; return 0; }
MOONBIT_FFI_EXPORT double orby_win_current_monitor_scale(uint64_t h) { (void)h; return 1.0; }
MOONBIT_FFI_EXPORT void orby_win_set_event_callback(void *c, void *p) { (void)c; (void)p; }
MOONBIT_FFI_EXPORT int32_t orby_win_run(void) { return 1; }
#endif
