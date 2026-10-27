///|
/// Physical client-area size in native pixels.
pub(all) struct Size {
  width : Int32
  height : Int32
} derive(Eq, Debug)

///|
pub extend Size with Eq::{equal, not_equal}

///|
pub extend Size with Debug::{to_repr}

///|
pub fn Size::new(width~ : Int32, height~ : Int32) -> Size {
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
pub extend LogicalSize with Eq::{equal, not_equal}

///|
pub extend LogicalSize with Debug::{to_repr}

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
  x : Int32
  y : Int32
} derive(Eq, Debug)

///|
pub extend Position with Eq::{equal, not_equal}

///|
pub extend Position with Debug::{to_repr}

///|
pub fn Position::new(x~ : Int32, y~ : Int32) -> Position {
  { x, y, }
}

///|
pub struct MonitorId {
  priv index_ : Int32
} derive(Eq, Debug)

///|
pub extend MonitorId with Eq::{equal, not_equal}

///|
pub extend MonitorId with Debug::{to_repr}

///|
pub fn MonitorId::from_index(index : Int32) -> MonitorId? {
  if index < 0 {
    None
  } else {
    Some({ index_: index, })
  }
}

///|
pub fn MonitorId::index(self : MonitorId) -> Int32 {
  self.index_
}

///|
pub(all) struct Monitor {
  id : MonitorId
  x : Int32
  y : Int32
  width : Int32
  height : Int32
  work_x : Int32
  work_y : Int32
  work_width : Int32
  work_height : Int32
  scale_factor : Double
} derive(Eq, Debug)

///|
pub extend Monitor with Eq::{equal, not_equal}

///|
pub extend Monitor with Debug::{to_repr}

///|
pub fn Monitor::new(
  id~ : MonitorId,
  x~ : Int32,
  y~ : Int32,
  width~ : Int32,
  height~ : Int32,
  work_x~ : Int32,
  work_y~ : Int32,
  work_width~ : Int32,
  work_height~ : Int32,
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
  raw : Int32
} derive(Eq, Debug)

///|
pub extend WindowId with Eq::{equal, not_equal}

///|
pub extend WindowId with Debug::{to_repr}

///|
pub fn WindowId::from_raw(raw : Int32) -> WindowId {
  { raw, }
}

///|
pub fn WindowId::raw(self : WindowId) -> Int32 {
  self.raw
}

///|
pub(all) enum ControlFlow {
  Poll
  Wait
} derive(Eq, Debug)

///|
pub extend ControlFlow with Eq::{equal, not_equal}

///|
pub extend ControlFlow with Debug::{to_repr}

///|
pub(all) enum InputState {
  Pressed
  Released
} derive(Eq, Debug)

///|
pub extend InputState with Eq::{equal, not_equal}

///|
pub extend InputState with Debug::{to_repr}

///|
pub(all) struct Modifiers {
  shift : Bool
  control : Bool
  alt : Bool
  meta : Bool
} derive(Eq, Debug)

///|
pub extend Modifiers with Eq::{equal, not_equal}

///|
pub extend Modifiers with Debug::{to_repr}

///|
pub fn Modifiers::new(
  shift~ : Bool = false,
  control~ : Bool = false,
  alt~ : Bool = false,
  meta~ : Bool = false,
) -> Modifiers {
  { shift, control, alt, meta, }
}

///|
pub(all) struct NativeKeyEvent {
  code : Int32
  state : InputState
  repeat : Bool
  modifiers : Modifiers
} derive(Eq, Debug)

///|
pub extend NativeKeyEvent with Eq::{equal, not_equal}

///|
pub extend NativeKeyEvent with Debug::{to_repr}

///|
pub fn NativeKeyEvent::new(
  code~ : Int32,
  state~ : InputState,
  repeat~ : Bool = false,
  modifiers~ : Modifiers = Modifiers::new(),
) -> NativeKeyEvent {
  { code, state, repeat, modifiers, }
}

///|
pub(all) enum MouseButton {
  Left
  Right
  Middle
  Back
  Forward
  Other(Int32)
} derive(Eq, Debug)

///|
pub extend MouseButton with Eq::{equal, not_equal}

///|
pub extend MouseButton with Debug::{to_repr}

///|
pub(all) struct ScrollDelta {
  x : Double
  y : Double
} derive(Eq, Debug)

///|
pub extend ScrollDelta with Eq::{equal, not_equal}

///|
pub extend ScrollDelta with Debug::{to_repr}

///|
pub fn ScrollDelta::new(x~ : Double, y~ : Double) -> ScrollDelta {
  { x, y, }
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
pub extend WindowEvent with Debug::{to_repr}

///|
pub(all) struct WindowOptions {
  title : String
  size : Size
  visible : Bool
  resizable : Bool
} derive(Eq, Debug)

///|
pub extend WindowOptions with Eq::{equal, not_equal}

///|
pub extend WindowOptions with Debug::{to_repr}

///|
pub fn WindowOptions::new(
  title~ : String = "Orby",
  size~ : Size = Size::new(width=800, height=600),
  visible~ : Bool = true,
  resizable~ : Bool = true,
) -> WindowOptions {
  { title, size, visible, resizable, }
}

///|
pub(all) suberror GeometryError {
  InvalidScaleFactor(Double)
} derive(Debug)

///|
pub extend GeometryError with Debug::{to_repr}

///|
pub(all) suberror InitError {
  /// Another EventLoop has already initialized Orby's process-global host.
  AlreadyActive
  UnsupportedHost(String)
  PlatformFailure(String)
} derive(Debug)

///|
pub extend InitError with Debug::{to_repr}

///|
/// Result of one external event-loop pump.
pub(all) enum ExternalPoll {
  Continue
  Exited(Int32)
} derive(Eq, Debug)

///|
pub extend ExternalPoll with Eq::{equal, not_equal}

///|
pub extend ExternalPoll with Debug::{to_repr}

///|
pub(all) suberror WindowError {
  CreationFailed(String)
  MonitorUnavailable(MonitorId)
  Destroyed
} derive(Debug)

///|
pub extend WindowError with Debug::{to_repr}

///|
pub(all) suberror AppError {
  StartupFailed(String)
  RuntimeFailed(String)
} derive(Debug)

///|
pub extend AppError with Debug::{to_repr}
