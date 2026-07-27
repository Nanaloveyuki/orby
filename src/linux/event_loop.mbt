///|
pub struct EventLoop {
  priv next_window_id : Ref[Int]
} derive(Debug)

///|
pub struct ActiveApp {
  priv next_window_id : Ref[Int]
} derive(Debug)

///|
pub fn EventLoop::new() -> EventLoop raise @core.InitError {
  if native_init() == 0 {
    raise @core.InitError::PlatformFailure(
      "GTK3 initialization failed; start Orby inside a graphical session",
    )
  }
  { next_window_id: Ref(1) }
}

///|
fn monitor_from_index(index : Int) -> @core.Monitor? {
  if index < 0 || index >= native_monitor_count() {
    None
  } else {
    match @core.MonitorId::from_index(index) {
      Some(id) =>
        Some(
          @core.Monitor::new(
            id~,
            x=native_monitor_metric(index, 0),
            y=native_monitor_metric(index, 1),
            width=native_monitor_metric(index, 2),
            height=native_monitor_metric(index, 3),
            work_x=native_monitor_metric(index, 4),
            work_y=native_monitor_metric(index, 5),
            work_width=native_monitor_metric(index, 6),
            work_height=native_monitor_metric(index, 7),
            scale_factor=native_monitor_scale(index),
          ),
        )
      None => None
    }
  }
}

///|
/// Returns every monitor available to the native desktop in index order.
pub fn EventLoop::available_monitors(_self : EventLoop) -> Array[@core.Monitor] {
  let monitors : Array[@core.Monitor] = []
  let count = native_monitor_count()
  for index in 0..<count {
    match monitor_from_index(index) {
      Some(monitor) => monitors.push(monitor)
      None => ()
    }
  }
  monitors
}

///|
/// Resolves a monitor ID against the current native display configuration.
pub fn EventLoop::monitor(
  _self : EventLoop,
  id : @core.MonitorId,
) -> @core.Monitor? {
  monitor_from_index(id.index())
}

///|
/// Returns the primary monitor when the native desktop exposes one.
pub fn EventLoop::primary_monitor(_self : EventLoop) -> @core.Monitor? {
  monitor_from_index(native_primary_monitor_index())
}

///|
fn EventLoop::active(self : EventLoop) -> ActiveApp {
  { next_window_id: self.next_window_id }
}

///|
pub fn ActiveApp::create_window(
  self : ActiveApp,
  options : @core.WindowOptions,
) -> Window raise @core.WindowError {
  let id = self.next_window_id.val
  self.next_window_id.val = id + 1
  let fixed = native_create_window(
    @utf8.encode(options.title, bom=false),
    options.size.width,
    options.size.height,
    options.visible,
    options.resizable,
    id,
  )
  if fixed == 0UL {
    raise @core.WindowError::CreationFailed("GTK window creation failed")
  }
  { id_: @core.WindowId::from_raw(id), fixed, alive: Ref(true) }
}

///|
pub fn ActiveApp::exit(_self : ActiveApp) -> Unit {
  native_exit(0)
}

///|
pub fn ActiveApp::exit_with_code(_self : ActiveApp, code : Int) -> Unit {
  native_exit(code)
}

///|
/// Controls how the UI thread proceeds after each native event batch. New
/// event loops start in `Wait`; `Poll` intentionally does not sleep.
pub fn ActiveApp::set_control_flow(
  _self : ActiveApp,
  control_flow : @core.ControlFlow,
) -> Unit {
  native_set_control_flow(
    match control_flow {
      Poll => true
      Wait => false
    },
  )
}
