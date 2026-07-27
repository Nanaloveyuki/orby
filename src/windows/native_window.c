#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellscalingapi.h>
#include <moonbit.h>
#include <stdint.h>

typedef void (*orby_event_callback)(void *, int32_t, int32_t, int32_t, int32_t, double);

static const wchar_t *ORBY_CLASS = L"OrbyWindow";
static orby_event_callback event_callback = NULL;
static void *event_context = NULL;
static int initialized_com = 0;
static int32_t window_count = 0;
static int exit_requested = 0;

static void emit_event(HWND hwnd, int32_t kind, int32_t arg0, int32_t arg1, double argd) {
  if (event_callback == NULL) return;
  const int32_t id = (int32_t)(intptr_t)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
  if (id > 0) event_callback(event_context, kind, id, arg0, arg1, argd);
}

static LRESULT CALLBACK orby_wndproc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  switch (message) {
  case WM_CLOSE:
    emit_event(hwnd, 1, 0, 0, 0.0);
    return 0;
  case WM_DESTROY:
    if (window_count > 0) window_count--;
    emit_event(hwnd, 2, 0, 0, 0.0);
    if (window_count == 0 && !exit_requested) PostQuitMessage(0);
    return 0;
  case WM_SIZE:
    emit_event(hwnd, 3, LOWORD(lparam), HIWORD(lparam), 0.0);
    return 0;
  case WM_DPICHANGED:
    emit_event(hwnd, 4, 0, 0, (double)HIWORD(wparam) / 96.0);
    return 0;
  case WM_SETFOCUS:
    emit_event(hwnd, 5, 1, 0, 0.0);
    return 0;
  case WM_KILLFOCUS:
    emit_event(hwnd, 5, 0, 0, 0.0);
    return 0;
  case WM_PAINT: {
    PAINTSTRUCT paint;
    BeginPaint(hwnd, &paint);
    EndPaint(hwnd, &paint);
    emit_event(hwnd, 6, 0, 0, 0.0);
    return 0;
  }
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
  HWND hwnd = CreateWindowExW(0, ORBY_CLASS, wide, style, CW_USEDEFAULT, CW_USEDEFAULT,
      width, height, NULL, NULL, GetModuleHandleW(NULL), NULL);
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
MOONBIT_FFI_EXPORT void orby_win_request_close(uint64_t hwnd) {
  PostMessageW((HWND)(uintptr_t)hwnd, WM_CLOSE, 0, 0);
}
MOONBIT_FFI_EXPORT void orby_win_exit(int32_t code) {
  exit_requested = 1;
  PostQuitMessage(code);
}
MOONBIT_FFI_EXPORT void orby_win_set_event_callback(orby_event_callback callback, void *context) {
  if (event_context != NULL) moonbit_decref(event_context);
  event_callback = callback;
  event_context = context;
}
MOONBIT_FFI_EXPORT int32_t orby_win_run(void) {
  MSG message;
  int32_t code = 0;
  while (GetMessageW(&message, NULL, 0, 0) > 0) { TranslateMessage(&message); DispatchMessageW(&message); }
  code = (int32_t)message.wParam;
  event_callback = NULL;
  if (event_context != NULL) moonbit_decref(event_context);
  event_context = NULL;
  exit_requested = 0;
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
MOONBIT_FFI_EXPORT void orby_win_request_close(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_win_exit(int32_t c) { (void)c; }
MOONBIT_FFI_EXPORT void orby_win_set_event_callback(void *c, void *p) { (void)c; (void)p; }
MOONBIT_FFI_EXPORT int32_t orby_win_run(void) { return 1; }
#endif
