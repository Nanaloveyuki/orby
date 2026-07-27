# orby

Orby is a native MoonBit application and window host for Win32 and GTK3/GDK.
It owns windows and their UI event loop, then exposes platform-specific
embedding hosts for native consumers such as MoonView.

`Nanaloveyuki/orby` is not compatible with Tao, winit, or Tauri.

## Status

The initial implementation targets a small application lifecycle, native
windows, resize/DPI/focus/redraw events, and WebView-ready host containers.
MoonView integration is validated after its Mooncakes package is available.

## Validation

```powershell
moon check --target native
moon test --target native
moon run src/examples/windows_smoke --target native
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
