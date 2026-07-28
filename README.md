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

## Usage

Import the root package and keep the created window until it is destroyed:

```mbt
import {
  "Nanaloveyuki/orby",
}

struct Example {
  mut window : @orby.Window?
}

pub impl @orby.App for Example with fn started(self, app) {
  self.window = Some(
    try! app.create_window(@orby.WindowOptions::new(title="Orby example")),
  )
}

pub impl @orby.App for Example with fn window_event(self, _app, _id, event) {
  match event {
    @orby.WindowEvent::CloseRequested =>
      match self.window {
        Some(window) => window.destroy()
        None => ()
      }
    _ => ()
  }
}

fn main raise {
  let event_loop = @orby.EventLoop::new()
  ignore(event_loop.run_app({ window: None }))
}
```

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

## Documentation

- [Development](docs/development.md): local setup, project requirements, and
  validation.
- [Contributing](CONTRIBUTING.md): pull request process.
- [Releasing](RELEASING.md): version and package release checklist.
