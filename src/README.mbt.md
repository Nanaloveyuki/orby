# Orby Root Package

`Nanaloveyuki/orby` is the consumer-facing package for native MoonBit desktop
applications. It creates and owns Win32 or GTK3/GDK windows, dispatches their
events on the UI thread, and provides a native child host for embedding a
runtime such as MoonView.

Import this package rather than `Nanaloveyuki/orby/windows` or
`Nanaloveyuki/orby/linux`; those packages are backend implementation details.

## Platform and Thread Model

Orby currently supports Windows and Linux with GTK3/GDK. Create the
`EventLoop`, create windows, and call every `Window`, `WebViewHost`, and
`ActiveApp` method from the same UI thread. Workers can use `EventLoop::proxy`
or `ActiveApp::proxy` to submit `Bytes`; `App::proxy_message` receives each
message on the UI thread in FIFO order.

The proxy copies messages into a native queue. A message is limited to 1 MiB
and the queue to 8 MiB; `post` returns `MessageTooLarge`, `QueueFull`, or
`Closed` instead of blocking a worker.

`EventLoop::new` raises `InitError` when the native host cannot initialize. On
Windows this requires an STA UI thread; on Linux it requires a graphical GTK3
session.

## Minimal Application

Keep each created `Window` in application state. A close request is only a
request: destroy the window from `window_event` to accept it.

```moonbit nocheck
import {
  "Nanaloveyuki/orby",
}

struct Example {
  mut window : @orby.Window?
}

pub impl @orby.App for Example with fn started(self, app) {
  self.window = Some(
    try! app.create_window(
      @orby.WindowOptions::new(
        title="Orby example",
        size=@orby.Size::new(width=960, height=640),
      ),
    ),
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
  let loop = @orby.EventLoop::new()
  ignore(loop.run_app({ window: None }))
}
```

Destroying the final native window exits the event loop. Call
`ActiveApp::exit` or `exit_with_code` when application state, rather than a
window, decides termination.

## Lifecycle and Failures

`App` receives callbacks in this order:

1. `started` runs after native callback installation and can create windows.
2. `window_event` receives per-window activity; `about_to_wait` runs after a
   native event batch.
3. `proxy_message` receives worker-submitted byte messages on the UI thread.
4. `exiting` runs exactly once after native loop cleanup.

Use `AppError::StartupFailed(reason)` from `started` when setup cannot
continue. `EventLoop::run_app` finishes native cleanup, invokes `exiting`, and
then raises the same startup error.

For a failure discovered asynchronously in a UI callback, call
`ActiveApp::fail(reason)`. The first reason wins, new application callbacks
are suppressed, and `run_app` raises `AppError::RuntimeFailed(reason)` after
calling `exiting`.

```moonbit nocheck
pub impl @orby.App for Example with fn about_to_wait(self, app) {
  if startup_work_failed() {
    app.fail("initial runtime setup failed")
  }
}

fn run_example() raise {
  let loop = @orby.EventLoop::new()
  let app = { window: None }
  try ignore(loop.run_app(app)) catch {
    @orby.AppError::StartupFailed(reason) => println("startup: \{reason}")
    @orby.AppError::RuntimeFailed(reason) => println("runtime: \{reason}")
  }
}
```

Do not use a blocking operation from `about_to_wait`, a window callback, or
any other UI-thread callback.

## Windows, Geometry, and Displays

`WindowOptions` configures title, physical client size, visibility, and
resizability at creation. `Size` is always physical client pixels;
`LogicalSize::to_physical` and `Size::to_logical` convert with an explicit,
validated scale factor.

Live windows provide title, visibility, resizability, decoration, minimization,
maximization, fullscreen, client-size constraints, redraw, close requests, and
outer-position requests. A Wayland compositor may ignore an outer-position
request. `set_fullscreen_on` accepts a `MonitorId` from the current monitor
snapshot.

`EventLoop::available_monitors`, `primary_monitor`, and `monitor` expose
current display snapshots. A `Window` also has `current_monitor` and
`scale_factor` queries.

Commands on a destroyed `Window` are no-ops. Queries and host acquisition are
checked: `inner_size`, `scale_factor`, fullscreen/minimized/maximized state,
`current_monitor`, `webview_host`, and `WebViewHost::native_handle` raise
`WindowError::Destroyed` after destruction. `create_window` can raise
`WindowError::CreationFailed`; `set_fullscreen_on` can raise
`WindowError::MonitorUnavailable`.

## Events and Input

`WindowEvent` reports close and destruction, resize, scale-factor changes,
focus, redraw requests, native key input, printable text input, pointer motion,
pointer enter/leave, mouse buttons, and smooth wheel deltas.

`NativeKeyEvent.code` intentionally stays backend-native. Use `TextInput` for
printable text. IME composition, touch, raw device input, cursor control, and
drag-and-drop are not part of the current API.

## WebView Hosts

Call `Window::webview_host` while the window is live, then pass
`WebViewHost::native_handle` to a child runtime that accepts a native parent
handle. Resize the child in response to `WindowEvent::Resized` and destroy the
child runtime before calling `Window::destroy`.

Orby owns neither MoonView configuration nor its asynchronous WebView event
contract. This release resolves the published
`Nanaloveyuki/moonview@0.1.0-beta.3` package, which in turn resolves AJNI
`0.2.0`. Follow the [MoonView integration guide](../docs/moonview-integration.md)
for creation, event, resize, resource-limit, failure, and teardown handling.

Orby has no Android backend. Android hosts should use MoonView's Android API
directly rather than treating an Orby `WebViewHost` as an Android surface.

## Public API Map

- `EventLoop` initializes the host, runs `App`, and queries displays.
- `ActiveApp` creates windows, controls loop scheduling, exits, or reports a
  checked runtime failure.
- `Window` owns one native window; `WebViewHost` exposes its live child host.
- `WindowOptions`, `Size`, `LogicalSize`, `Position`, `Monitor`, and
  `MonitorId` describe creation and display state.
- `WindowEvent`, `NativeKeyEvent`, `Modifiers`, `MouseButton`, and
  `ScrollDelta` describe input and native window activity.
- `InitError`, `GeometryError`, `WindowError`, and `AppError` describe checked
  failures.
