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
) -> Size raise GeometryError {
  guard validate_scale_factor(scale_factor) else {
    raise GeometryError::InvalidScaleFactor(scale_factor)
  }
  Size::new(
    width=(self.width * scale_factor).to_int(),
    height=(self.height * scale_factor).to_int(),
  )
}

///|
pub fn Size::to_logical(
  self : Size,
  scale_factor : Double,
) -> LogicalSize raise GeometryError {
  guard validate_scale_factor(scale_factor) else {
    raise GeometryError::InvalidScaleFactor(scale_factor)
  }
  LogicalSize::new(
    width=self.width.to_double() / scale_factor,
    height=self.height.to_double() / scale_factor,
  )
}

///|
pub(all) struct Position {
  x : Int
  y : Int
} derive(Eq, Debug)

///|
pub fn Position::new(x~ : Int, y~ : Int) -> Position {
  { x, y }
}

///|
pub struct MonitorId {
  priv index_ : Int
} derive(Eq, Debug)

///|
pub fn MonitorId::from_index(index : Int) -> MonitorId? {
  if index < 0 {
    None
  } else {
    Some({ index_: index })
  }
}

///|
pub fn MonitorId::index(self : MonitorId) -> Int {
  self.index_
}

///|
pub(all) struct Monitor {
  id : MonitorId
  x : Int
  y : Int
  width : Int
  height : Int
  work_x : Int
  work_y : Int
  work_width : Int
  work_height : Int
  scale_factor : Double
} derive(Eq, Debug)

///|
pub fn Monitor::new(
  id~ : MonitorId,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  work_x~ : Int,
  work_y~ : Int,
  work_width~ : Int,
  work_height~ : Int,
  scale_factor~ : Double,
) -> Monitor {
  {
    id,
    x,
    y,
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
    work_x,
    work_y,
    work_width: if work_width < 1 {
      1
    } else {
      work_width
    },
    work_height: if work_height < 1 {
      1
    } else {
      work_height
    },
    scale_factor: if validate_scale_factor(scale_factor) {
      scale_factor
    } else {
      1.0
    },
  }
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
pub(all) enum InputState {
  Pressed
  Released
} derive(Eq, Debug)

///|
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

///|
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
pub(all) enum MouseButton {
  Left
  Right
  Middle
  Back
  Forward
  Other(Int)
} derive(Eq, Debug)

///|
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
pub(all) suberror GeometryError {
  InvalidScaleFactor(Double)
} derive(Debug)

///|
pub(all) suberror InitError {
  UnsupportedHost(String)
  PlatformFailure(String)
} derive(Debug)

///|
pub(all) suberror WindowError {
  CreationFailed(String)
  MonitorUnavailable(MonitorId)
  Destroyed
} derive(Debug)

///|
pub(all) suberror AppError {
  StartupFailed(String)
  RuntimeFailed(String)
} derive(Debug)
