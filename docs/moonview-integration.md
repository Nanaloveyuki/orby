# MoonView Integration

Orby's `moon.mod` resolves the published
`Nanaloveyuki/moonview@0.1.0-beta.3` package. MoonView resolves
`Nanaloveyuki/ajni@0.2.0` transitively; an Orby application does not need a
direct AJNI dependency for the desktop integration below.

This guide applies to Orby's Windows and GTK3/GDK backends. Orby does not
provide an Android window backend or Android `WebViewHost`.

## Create the Host

Create the Orby window first, obtain its live child host, then create MoonView
with that native handle. All calls and callbacks below run on Orby's UI thread.

```moonbit nocheck
let window = try! app.create_window(
  @orby.WindowOptions::new(title="MoonView host"),
)
let host = try! window.webview_host()
let native_host = try! host.native_handle()
let options = @moonview.WebViewOptions::new(
  bounds=@moonview.Rect::new(x=0, y=0, width=960, height=640),
  initial_url="app://index.html",
  resource_limits=@moonview.WebViewResourceLimits::new(
    max_pending_commands=256,
    max_pending_command_bytes=4 * 1024 * 1024,
    max_protocol_request_body_bytes=4 * 1024 * 1024,
  ),
  on_event=event => self.handle_webview_event(event),
)
match @moonview.WebView::create(native_host, options) {
  Ok(view) => self.view = Some(view)
  Err(_) => {
    window.destroy()
    raise @orby.AppError::StartupFailed("MoonView creation was rejected")
  }
}
```

Register a custom scheme before creating any WebView that navigates to it.
MoonView's `WebView::create` only means the native creation request was
accepted. Wait for `WebViewEvent::Ready` before treating the instance as ready
for application work.

`WebViewResourceLimits::new` defaults to the values shown above. Lower them
when the application has a bounded command or protocol-payload budget; `0`
disables the corresponding limit. Negative values make creation fail.

## Keep the Two Lifecycles Aligned

Store the window and WebView in application state. On every
`WindowEvent::Resized`, update the child bounds using the physical Orby size.

```moonbit nocheck
@orby.WindowEvent::Resized(size) =>
  match self.view {
    Some(view) => ignore(
      view.set_bounds(
        @moonview.Rect::new(x=0, y=0, width=size.width, height=size.height),
      ),
    )
    None => ()
  }
```

The application owns teardown order. On `CloseRequested`, successful work, or
an asynchronous MoonView failure, call `WebView::destroy` before
`Window::destroy`. Both the destroy path and window close path should be
idempotent because close and asynchronous events can race within the same UI
event sequence. After `WindowEvent::Destroyed`, `WebViewHost::native_handle`
must raise `WindowError::Destroyed` and must not be reused.

## Failures and Events

Use `AppError::StartupFailed` when `WebView::create` is rejected during
`App::started`. For a `CreationFailed`, `ScriptFailed`, or other fatal event
observed after startup, destroy the WebView and its window, then call
`ActiveApp::fail(reason)`. `EventLoop::run_app` reports that as
`AppError::RuntimeFailed` after native cleanup.

Do not block inside `on_event` or another Orby UI callback. Protocol responses,
page messages, navigation policy, and script results belong to MoonView's
event contract; respond through the stored live `WebView` only.

## Executable References

The repository keeps end-to-end desktop examples that exercise custom-scheme
protocol responses, page messaging, script evaluation, resize, checked failure
handling, and runtime-before-window teardown:

- `src/examples/moonview_windows`
- `src/examples/moonview_linux`

Run the Windows example locally with the configured WebView2 SDK. The Linux
example is exercised by the native Linux CI job.
