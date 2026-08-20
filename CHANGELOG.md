# Changelog

## 0.1.0-beta.6

- Pin the project to MoonBit 0.10.9.
- Update the desktop WebView host integration to MoonView 0.1.0-beta.9.
- Keep external event-loop termination and bounded native cleanup observable
  for applications embedding Orby in another runtime.

## 0.1.0-beta.5

- Reject concurrent `EventLoop::new` calls with `InitError::AlreadyActive` so
  a second host cannot overwrite process-global Win32 or GTK state.
- Change `ExternalAppLoop::poll` to return `ExternalPoll`, preserving native
  loop termination and its exit code for embedding runtimes.

## 0.1.0-beta.4

- Added `Window::focus()` for restoring, showing, and requesting activation of
  a live top-level window on Win32 and GTK3.

## 0.1.0-beta.3

- Regenerated the public package metadata with MoonBit 0.1.20260803 / moonc
  0.10.6, keeping the package compatible with the current MoonBit toolchain.

## 0.1.0-beta.2

- Added `EventLoop::start_external_app` and `ExternalAppLoop` for native host
  loops driven by an external async runtime. The driver accepts the runtime's
  timeout, exposes a foreign-thread-safe native wake callback, and preserves
  the existing application teardown ordering.
- Added Win32 and GTK3 single-step message pumping with a bounded wait. The
  existing `EventLoop::run_app` remains the default blocking API.

## 0.1.0-beta.1

- Added a native, worker-safe event-loop proxy. EventLoop::proxy and
  ActiveApp::proxy accept copied byte messages and deliver them to
  App::proxy_message on the UI thread.
- Added explicit closed, oversized-message, and bounded-queue outcomes, plus
  Windows and Linux native wakeups and a cross-platform proxy smoke.

## 0.1.0-beta.0

- Win32 and GTK3/GDK native windows, lifecycle, geometry, display snapshots,
  basic input, fullscreen, and MoonView host integration.
- A common `Nanaloveyuki/orby` application facade with checked startup and
  runtime lifecycle errors.
- Native CI gates for Orby and MoonView smokes on Windows and Linux, including
  assertions that a created WebView is destroyed before its host window.
- Published `Nanaloveyuki/moonview@0.1.0-beta.3` integration, which resolves
  `Nanaloveyuki/ajni@0.2.0` transitively.

## Compatibility

0.1.0-beta.0 is the initial public beta. Applications import
`Nanaloveyuki/orby`; the `windows` and `linux` packages are implementation
backends, not consumer APIs. The public API may change before the stable 0.1.0
release.
