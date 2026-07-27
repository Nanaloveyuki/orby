///|
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
pub(all) enum WindowEvent {
  CloseRequested
  Destroyed
  Resized(Size)
  ScaleFactorChanged(Double)
  FocusChanged(Bool)
  RedrawRequested
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
