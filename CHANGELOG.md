# Changelog

## 0.1.0

- Win32 and GTK3/GDK native windows, lifecycle, geometry, display snapshots,
  basic input, fullscreen, and MoonView host integration.
- A common `Nanaloveyuki/orby` application facade with checked startup and
  runtime lifecycle errors.
- Native CI gates for Orby and MoonView smokes on Windows and Linux, including
  assertions that a created WebView is destroyed before its host window.
- Published `Nanaloveyuki/moonview@0.1.0-beta.3` integration, which resolves
  `Nanaloveyuki/ajni@0.2.0` transitively.

## Compatibility

0.1.0 is the initial public API. Applications import `Nanaloveyuki/orby`; the
`windows` and `linux` packages are implementation backends, not consumer APIs.
