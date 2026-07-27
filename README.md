# orby

Orby is a native MoonBit application and window host for Win32 and GTK3/GDK.
It owns windows and their UI event loop through the common
`Nanaloveyuki/orby` package, then exposes embedding hosts for native consumers
such as MoonView.

`Nanaloveyuki/orby` is not compatible with Tao, winit, or Tauri.

## API

Import `Nanaloveyuki/orby`; its `App`, `EventLoop`, `ActiveApp`, `Window`,
events, monitor types, and `WebViewHost` are the cross-platform public API.
The `windows` and `linux` packages are backend implementation details and are
not application-facing APIs.

All Orby calls and callbacks belong to the UI thread. A worker-thread event
loop proxy is not available yet.

`App::started` may raise `AppError::StartupFailed`. For asynchronous setup or
runtime failures, call `ActiveApp::fail(reason)` from a UI callback. The loop
stops, invokes `App::exiting` once, and `EventLoop::run_app` raises
`AppError::RuntimeFailed`. Destroy a child runtime such as MoonView before its
parent `Window`; Orby does not reverse application-owned teardown ordering.

## Status

The initial implementation targets a small application lifecycle, native
windows, resize/DPI/focus/redraw events, and WebView-ready host containers.
MoonView integration is validated on both supported platforms in CI.

`CloseRequested` is application-controlled: call `Window::destroy` from the
event handler to accept it, or do nothing to cancel it. `request_close` uses
the same path for programmatic closure. Destroying the final window ends the
event loop automatically; `ActiveApp::exit_with_code` can set a process result.
Calls on a destroyed `Window` are safe no-ops; use `is_destroyed` before
retaining or reusing a window handle across lifecycle callbacks.

Commands on a destroyed window are no-ops. Queries, `webview_host`, and
`WebViewHost::native_handle` require a live native window and raise
`WindowError::Destroyed`. Destroy the MoonView instance before its Orby window.

Window `Size` values are physical client-area pixels. Use `LogicalSize` with a
window's `scale_factor` for device-independent layout, and use `inner_size` /
`set_inner_size` when sizing native content. `set_outer_position` is a request
that may be ignored by a Wayland compositor.

Keyboard and pointer input arrive through `WindowEvent`. `NativeKeyEvent.code`
is intentionally backend-native, while `TextInput` carries printable Unicode
text and modifiers use `Shift`, `Control`, `Alt`, and `Meta`. IME composition,
touch, and raw device events remain outside the current API.

## Validation

```powershell
moon check --target native
moon test --target native
moon run src/examples/windows_smoke --target native
moon run src/examples/failure_smoke --target native
```

On Linux, install MoonBit in the target distribution, then run:

```sh
sh scripts/run-linux-smoke.sh
```

The script builds with the system C linker before executing the binary; this is
required because GTK3 link flags are not usable with MoonBit's `tcc -run`
debug path. The Linux backend requires GTK3 development files. MoonView
integration also requires its published Mooncakes package and WebKitGTK 4.1.

With a WebView2 SDK available, run the Windows integration smoke:

```powershell
$env:MOONVIEW_WEBVIEW2_SDK_DIR = "F:\path\to\Microsoft.Web.WebView2"
moon run src/examples/moonview_windows --target native
```

On Linux, run `sh scripts/run-moonview-linux-smoke.sh` after installing the
MoonView package dependencies.
