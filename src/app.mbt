///|
/// Application callbacks run only on Orby's UI thread.
pub(open) trait App {
  fn started(Self, ActiveApp) -> Unit raise AppError = _
  fn window_event(Self, ActiveApp, WindowId, WindowEvent) -> Unit = _
  fn about_to_wait(Self, ActiveApp) -> Unit = _
  fn exiting(Self, ActiveApp) -> Unit = _
}

///|
impl App with fn started(_self, _app) {
  ()
}

///|
impl App with fn window_event(_self, _app, _id, _event) {
  ()
}

///|
impl App with fn about_to_wait(_self, _app) {
  ()
}

///|
impl App with fn exiting(_self, _app) {
  ()
}

///|
pub struct EventLoop {
  priv backend : NativeBackend
  priv next_window_id : Ref[Int]
  priv runtime_failure : Ref[String?]
} derive(Debug)

///|
pub struct ActiveApp {
  priv backend : NativeBackend
  priv next_window_id : Ref[Int]
  priv runtime_failure : Ref[String?]
} derive(Debug)

///|
pub fn EventLoop::new() -> EventLoop raise InitError {
  {
    backend: initialize_backend(),
    next_window_id: Ref(1),
    runtime_failure: Ref(None),
  }
}

///|
fn EventLoop::active(self : EventLoop) -> ActiveApp {
  {
    backend: self.backend,
    next_window_id: self.next_window_id,
    runtime_failure: self.runtime_failure,
  }
}

///|
/// Requests a checked application failure from a UI callback. The first reason
/// wins. Callers must destroy child runtimes before their parent windows.
pub fn ActiveApp::fail(self : ActiveApp, reason : String) -> Unit {
  if record_runtime_failure(self.runtime_failure, reason) {
    native_exit(self.backend, 1)
  }
}

///|
fn record_runtime_failure(failure : Ref[String?], reason : String) -> Bool {
  match failure.val {
    None => {
      failure.val = Some(reason)
      true
    }
    Some(_) => false
  }
}

///|
pub fn ActiveApp::exit(self : ActiveApp) -> Unit {
  native_exit(self.backend, 0)
}

///|
pub fn ActiveApp::exit_with_code(self : ActiveApp, code : Int) -> Unit {
  native_exit(self.backend, code)
}

///|
pub fn ActiveApp::set_control_flow(
  self : ActiveApp,
  control_flow : ControlFlow,
) -> Unit {
  native_set_control_flow(
    self.backend,
    match control_flow {
      Poll => true
      Wait => false
    },
  )
}

///|
pub fn ActiveApp::create_window(
  self : ActiveApp,
  options : WindowOptions,
) -> Window raise WindowError {
  let id = self.next_window_id.val
  self.next_window_id.val = id + 1
  let handle = native_create_window(
    self.backend,
    @utf8.encode(options.title, bom=false),
    options.size.width,
    options.size.height,
    options.visible,
    options.resizable,
    id,
  )
  if handle == 0UL {
    raise WindowError::CreationFailed("native window creation returned null")
  }
  {
    id_: WindowId::from_raw(id),
    handle,
    alive: Ref(true),
    backend: self.backend,
  }
}

///|
pub fn EventLoop::available_monitors(self : EventLoop) -> Array[Monitor] {
  available_monitors_for(self.backend)
}

///|
pub fn EventLoop::monitor(self : EventLoop, id : MonitorId) -> Monitor? {
  monitor_from_index(self.backend, id.index())
}

///|
pub fn EventLoop::primary_monitor(self : EventLoop) -> Monitor? {
  monitor_from_index(self.backend, native_primary_monitor_index(self.backend))
}

///|
pub fn[A : App] EventLoop::run_app(
  self : EventLoop,
  app : A,
) -> Int raise AppError {
  let active = self.active()
  let startup_failure : Ref[String?] = Ref(None)
  native_set_event_callback(self.backend, fn(
    kind,
    id,
    arg0,
    arg1,
    argd0,
    argd1,
  ) {
    if active.runtime_failure.val is None {
      dispatch_event(app, active, kind, id, arg0, arg1, argd0, argd1)
    }
  })
  app.started(active) catch {
    AppError::StartupFailed(reason) => {
      startup_failure.val = Some(reason)
      native_exit(self.backend, 1)
    }
    AppError::RuntimeFailed(reason) => {
      startup_failure.val = Some(reason)
      native_exit(self.backend, 1)
    }
  }
  let code = native_run(self.backend)
  app.exiting(active)
  match startup_failure.val {
    Some(reason) => raise AppError::StartupFailed(reason)
    None =>
      match active.runtime_failure.val {
        Some(reason) => raise AppError::RuntimeFailed(reason)
        None => code
      }
  }
}

///|
fn available_monitors_for(backend : NativeBackend) -> Array[Monitor] {
  let monitors : Array[Monitor] = []
  let count = native_monitor_count(backend)
  for index in 0..<count {
    match monitor_from_index(backend, index) {
      Some(monitor) => monitors.push(monitor)
      None => ()
    }
  }
  monitors
}

///|
fn monitor_from_index(backend : NativeBackend, index : Int) -> Monitor? {
  if index < 0 || index >= native_monitor_count(backend) {
    None
  } else {
    match MonitorId::from_index(index) {
      Some(id) =>
        Some(
          Monitor::new(
            id~,
            x=native_monitor_metric(backend, index, 0),
            y=native_monitor_metric(backend, index, 1),
            width=native_monitor_metric(backend, index, 2),
            height=native_monitor_metric(backend, index, 3),
            work_x=native_monitor_metric(backend, index, 4),
            work_y=native_monitor_metric(backend, index, 5),
            work_width=native_monitor_metric(backend, index, 6),
            work_height=native_monitor_metric(backend, index, 7),
            scale_factor=native_monitor_scale(backend, index),
          ),
        )
      None => None
    }
  }
}

///|
fn[A : App] dispatch_event(
  app : A,
  active : ActiveApp,
  kind : Int,
  id : Int,
  arg0 : Int,
  arg1 : Int,
  argd0 : Double,
  argd1 : Double,
) -> Unit {
  match kind {
    14 => app.about_to_wait(active)
    _ => {
      let window_id = WindowId::from_raw(id)
      match kind {
        1 => app.window_event(active, window_id, CloseRequested)
        2 => app.window_event(active, window_id, Destroyed)
        3 =>
          app.window_event(
            active,
            window_id,
            Resized(Size::new(width=arg0, height=arg1)),
          )
        4 => app.window_event(active, window_id, ScaleFactorChanged(argd0))
        5 => app.window_event(active, window_id, FocusChanged(arg0 != 0))
        6 => app.window_event(active, window_id, RedrawRequested)
        7 =>
          app.window_event(
            active,
            window_id,
            KeyInput(
              NativeKeyEvent::new(
                code=arg0,
                state=if (arg1 & 16) != 0 { Pressed } else { Released },
                repeat=(arg1 & 32) != 0,
                modifiers=Modifiers::new(
                  shift=(arg1 & 1) != 0,
                  control=(arg1 & 2) != 0,
                  alt=(arg1 & 4) != 0,
                  meta=(arg1 & 8) != 0,
                ),
              ),
            ),
          )
        8 =>
          match arg0.to_char() {
            Some(character) =>
              app.window_event(
                active,
                window_id,
                TextInput(character.to_string()),
              )
            None => ()
          }
        9 =>
          app.window_event(
            active,
            window_id,
            PointerMoved(Position::new(x=arg0, y=arg1)),
          )
        10 => app.window_event(active, window_id, PointerEntered)
        11 => app.window_event(active, window_id, PointerLeft)
        12 =>
          app.window_event(
            active,
            window_id,
            MouseInput(
              match arg0 {
                1 => MouseButton::Left
                2 => MouseButton::Right
                3 => MouseButton::Middle
                4 => MouseButton::Back
                5 => MouseButton::Forward
                _ => MouseButton::Other(arg0)
              },
              if (arg1 & 16) != 0 {
                Pressed
              } else {
                Released
              },
              Modifiers::new(
                shift=(arg1 & 1) != 0,
                control=(arg1 & 2) != 0,
                alt=(arg1 & 4) != 0,
                meta=(arg1 & 8) != 0,
              ),
            ),
          )
        13 =>
          app.window_event(
            active,
            window_id,
            MouseWheel(
              ScrollDelta::new(x=argd0, y=argd1),
              Modifiers::new(
                shift=(arg1 & 1) != 0,
                control=(arg1 & 2) != 0,
                alt=(arg1 & 4) != 0,
                meta=(arg1 & 8) != 0,
              ),
            ),
          )
        _ => ()
      }
    }
  }
}
