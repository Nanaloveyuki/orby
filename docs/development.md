# Developing Orby

## Project Requirements

- Use the published Mooncakes dependency graph; do not add machine-local paths
  to manifests, generated source, examples, or release artifacts.
- Keep consumer-facing application APIs in `Nanaloveyuki/orby`. The `windows`
  and `linux` packages are backend implementation details.
- Preserve UI-thread ownership and destroy child runtimes before their parent
  Orby windows.
- Run `moon info --target native` after changing a public API and commit the
  generated `pkg.generated.mbti` diff. Do not edit generated interfaces by
  hand.
- Keep changes focused and update tests and documentation with behavior changes.

## Local Setup

Use MoonBit compiler `0.10.17+d971670cd` with CLI `0.1.20261023`.
`.moonbit-toolchain` selects the exact installer archive; `.moon-version`
records the CLI version. Install the pinned archive on Unix with:

```sh
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- "$(cat .moonbit-toolchain)"
```

On Windows:

```powershell
$env:MOONBIT_INSTALL_VERSION = (Get-Content .moonbit-toolchain -Raw).Trim()
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

Confirm both versions with `moon version --all`, then run `moon update`.
Do not pass the CLI version to the installer. Windows native tests and smoke
commands also require a compatible WebView2 SDK because MoonView is a module dependency:

```powershell
$env:MOONVIEW_WEBVIEW2_SDK_DIR = "F:\path\to\Microsoft.Web.WebView2"
```

The CI workflow downloads the supported SDK version automatically. On Linux,
install GTK3, WebKitGTK 4.1, `pkg-config`, and `xvfb` before native validation.

## Validation

Run the Windows-capable validation path from the repository root:

```powershell
moon fmt --check
moon check --target native
moon test --target native
moon run src/examples/windows_smoke --target native
moon run src/examples/failure_smoke --target native
moon run src/examples/proxy_smoke --target native
moon run src/examples/moonview_windows --target native
```

On Linux, use the scripts so MoonBit receives the system linker flags:

```sh
xvfb-run --auto-servernum sh scripts/run-linux-smoke.sh
xvfb-run --auto-servernum moon run src/examples/proxy_smoke --target native
xvfb-run --auto-servernum sh scripts/run-moonview-linux-smoke.sh
```

The Linux scripts are required because GTK3 link flags are not usable through
MoonBit's `tcc -run` debug path.

## Change Workflow

Start from the current `main`, use a focused branch, and use a concise
Conventional Commit-style subject such as `fix(window): guard host lifetime`.
Run the relevant validation before review. Public API changes must include the
`moon info` interface diff and a documented migration impact.

Do not commit local SDKs, build products, `.mooncakes`, or temporary planning
files under `tmp/`.
