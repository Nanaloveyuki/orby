///|
/// Physical client-area size in native pixels.
pub(all) struct Size {
  width : Int
  height : Int
} derive(Eq, Debug)

///|
pub fn Size::new(width~ : Int, height~ : Int) -> Size {
  {
    width: if width < 1 {
      1
    } else {
      width
    },
    height: if height < 1 {
      1
    } else {
      height
    },
  }
}

///|
pub fn validate_scale_factor(scale_factor : Double) -> Bool {
  scale_factor > 0.0 &&
  !Double::is_nan(scale_factor) &&
  !Double::is_inf(scale_factor)
}

///|
/// Device-independent size. Convert explicitly with a valid scale factor
/// before passing dimensions to a native window.
pub(all) struct LogicalSize {
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub fn LogicalSize::new(width~ : Double, height~ : Double) -> LogicalSize {
  {
    width: if width > 0.0 && !Double::is_nan(width) && !Double::is_inf(width) {
      width
    } else {
      1.0
    },
    height: if height > 0.0 &&
      !Double::is_nan(height) &&
      !Double::is_inf(height) {
      height
    } else {
      1.0
    },
  }
}

///|
pub fn LogicalSize::to_physical(
  self : LogicalSize,
  scale_factor : Double,
) -> Size {
  guard validate_scale_factor(scale_factor) else {
    abort("scale_factor must be finite and positive")
  }
  Size::new(
    width=(self.width * scale_factor).to_int(),
    height=(self.height * scale_factor).to_int(),
  )
}

///|
pub fn Size::to_logical(self : Size, scale_factor : Double) -> LogicalSize {
  guard validate_scale_factor(scale_factor) else {
    abort("scale_factor must be finite and positive")
  }
  LogicalSize::new(
    width=self.width.to_double() / scale_factor,
    height=self.height.to_double() / scale_factor,
  )
}

///|
/// Physical desktop coordinate. Wayland compositors may ignore position
/// requests.
pub(all) struct Position {
  x : Int
  y : Int
} derive(Eq, Debug)

///|
pub fn Position::new(x~ : Int, y~ : Int) -> Position {
  { x, y }
}

///|
pub(all) struct WindowId {
  raw : Int
} derive(Eq, Debug)

///|
pub fn WindowId::from_raw(raw : Int) -> WindowId {
  { raw, }
}

///|
pub fn WindowId::raw(self : WindowId) -> Int {
  self.raw
}

///|
pub(all) enum ControlFlow {
  Poll
  Wait
} derive(Eq, Debug)

///|
/// State of a keyboard or pointer button.
pub(all) enum InputState {
  Pressed
  Released
} derive(Eq, Debug)

///|
/// Cross-platform modifier state sampled with an input event.
pub(all) struct Modifiers {
  shift : Bool
  control : Bool
  alt : Bool
  meta : Bool
} derive(Eq, Debug)

///|
pub fn Modifiers::new(
  shift? : Bool = false,
  control? : Bool = false,
  alt? : Bool = false,
  meta? : Bool = false,
) -> Modifiers {
  { shift, control, alt, meta }
}

///| A platform-native keyboard code. Codes are intentionally not normalized

///|
/// between Win32 and GTK; use `TextInput` for layout-aware text.
pub(all) struct NativeKeyEvent {
  code : Int
  state : InputState
  repeat : Bool
  modifiers : Modifiers
} derive(Eq, Debug)

///|
pub fn NativeKeyEvent::new(
  code~ : Int,
  state~ : InputState,
  repeat? : Bool = false,
  modifiers? : Modifiers = Modifiers::new(),
) -> NativeKeyEvent {
  { code, state, repeat, modifiers }
}

///|
/// Pointer buttons normalized across Win32 and GTK.
pub(all) enum MouseButton {
  Left
  Right
  Middle
  Back
  Forward
  Other(Int)
} derive(Eq, Debug)

///| Scroll values are backend-native smooth deltas when available, otherwise

///|
/// unit line steps. Positive values move right and down.
pub(all) struct ScrollDelta {
  x : Double
  y : Double
} derive(Eq, Debug)

///|
pub fn ScrollDelta::new(x~ : Double, y~ : Double) -> ScrollDelta {
  { x, y }
}

///|
pub(all) enum WindowEvent {
  CloseRequested
  Destroyed
  Resized(Size)
  ScaleFactorChanged(Double)
  FocusChanged(Bool)
  RedrawRequested
  KeyInput(NativeKeyEvent)
  /// A printable Unicode scalar. IME composition is not represented yet.
  TextInput(String)
  PointerMoved(Position)
  PointerEntered
  PointerLeft
  MouseInput(MouseButton, InputState, Modifiers)
  MouseWheel(ScrollDelta, Modifiers)
} derive(Debug)

///|
pub(all) struct WindowOptions {
  title : String
  size : Size
  visible : Bool
  resizable : Bool
} derive(Eq, Debug)

///|
pub fn WindowOptions::new(
  title? : String = "Orby",
  size? : Size = Size::new(width=800, height=600),
  visible? : Bool = true,
  resizable? : Bool = true,
) -> WindowOptions {
  { title, size, visible, resizable }
}

///|
pub(all) suberror InitError {
  UnsupportedHost(String)
  PlatformFailure(String)
} derive(Debug)

///|
pub(all) suberror WindowError {
  CreationFailed(String)
  Destroyed
} derive(Debug)
