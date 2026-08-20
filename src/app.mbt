///|
/// Application callbacks run only on Orby's UI thread.
pub(open) trait App {
  fn started(Self, ActiveApp) -> Unit raise AppError = _
  fn window_event(Self, ActiveApp, WindowId, WindowEvent) -> Unit = _
  fn proxy_message(Self, ActiveApp, Bytes) -> Unit = _
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
impl App with fn proxy_message(_self, _app, _message) {
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
  priv proxy_generation : UInt64
  priv next_window_id : Ref[Int]
  priv runtime_failure : Ref[String?]
} derive(Debug)

///|
pub struct ActiveApp {
  priv backend : NativeBackend
  priv proxy_generation : UInt64
  priv next_window_id : Ref[Int]
  priv runtime_failure : Ref[String?]
} derive(Debug)

///|
priv struct ExternalAppState[A] {
  app : A
  active : ActiveApp
  mut terminated : Bool
  mut exit_code : Int?
}

///|
let event_loop_active : Ref[Bool] = Ref(false)

///|
/// A manually pumped application loop for integration with a foreign runtime.
///
/// `poll` and `terminate` must run on Orby's UI thread. The callback returned
/// by `wakeup_callback_for_foreign_thread` is the sole exception: it is safe
/// to invoke from a foreign thread because it calls directly into the native
/// backend without accessing MoonBit-managed application state.
pub struct ExternalAppLoop[A] {
  priv backend : NativeBackend
  priv state : Ref[ExternalAppState[A]]
}

///|
fn reserve_event_loop() -> Unit raise InitError {
  if event_loop_active.val || native_event_loop_is_active() {
    raise InitError::AlreadyActive
  }
  event_loop_active.val = true
}

///|
fn release_event_loop() -> Unit {
  event_loop_active.val = false
}

///|
pub fn EventLoop::new() -> EventLoop raise InitError {
  reserve_event_loop()
  let backend = {
    errdefer release_event_loop()
    initialize_backend()
  }
  let proxy_generation = native_open_proxy(backend)
  {
    backend,
    proxy_generation,
    next_window_id: Ref(1),
    runtime_failure: Ref(None),
  }
}

///|
fn EventLoop::active(self : EventLoop) -> ActiveApp {
  {
    backend: self.backend,
    proxy_generation: self.proxy_generation,
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
/// Starts an application without taking ownership of the native event loop.
///
/// Call `poll` repeatedly from the embedding event loop, then call `terminate`
/// exactly once after the embedding runtime has stopped. This is intended for
/// integrations such as `moonbitlang/async`'s external event loop support.
pub fn[A : App] EventLoop::start_external_app(
  self : EventLoop,
  app : A,
) -> ExternalAppLoop[A] raise AppError {
  let active = self.active()
  let state = Ref({ app, active, terminated: false, exit_code: None })
  native_set_event_callback(self.backend, fn(
    kind,
    id,
    arg0,
    arg1,
    argd0,
    argd1,
  ) {
    let current = state.val
    if current.active.runtime_failure.val is None {
      dispatch_event(
        current.app,
        current.active,
        kind,
        id,
        arg0,
        arg1,
        argd0,
        argd1,
      )
    }
  })
  errdefer {
    ignore(native_finish(self.backend))
    release_event_loop()
    state.val.app.exiting(active)
  }
  state.val.app.started(active)
  { backend: self.backend, state }
}

///|
/// Pumps pending native events, then waits for no longer than `timeout`
/// milliseconds. Omitting `timeout` waits indefinitely. `Exited(code)` means
/// native cleanup and `App::exiting` have already run.
pub fn[A : App] ExternalAppLoop::poll(
  self : ExternalAppLoop[A],
  timeout? : Int,
) -> ExternalPoll raise AppError {
  if self.state.val.terminated {
    return Exited(self.state.val.exit_code.unwrap_or(0))
  }
  let status = native_poll(self.backend, timeout?)
  if status < 0 {
    ignore(self.terminate() catch { _ => 0 })
    raise AppError::RuntimeFailed("native event loop polling failed")
  }
  match self.state.val.active.runtime_failure.val {
    Some(reason) => {
      ignore(self.terminate() catch { _ => 0 })
      raise AppError::RuntimeFailed(reason)
    }
    None => if status == 0 { Exited(self.terminate()) } else { Continue }
  }
}

///|
/// Returns a wakeup callback suitable for a native foreign thread.
///
/// The callback does not inspect application state and only invokes the native
/// backend wake primitive. Do not wrap it in another MoonBit callback that
/// captures MoonBit-managed values before passing it to a foreign thread.
pub fn[A] ExternalAppLoop::wakeup_callback_for_foreign_thread(
  self : ExternalAppLoop[A],
) -> FuncRef[() -> Unit] {
  let _ = self
  () => wake_external_loop_from_foreign_thread()
}

///|
/// Releases native event-loop state and invokes the application's `exiting`
/// callback. It is idempotent so cleanup paths can safely call it after an
/// initialization or runtime failure.
pub fn[A : App] ExternalAppLoop::terminate(
  self : ExternalAppLoop[A],
) -> Int raise AppError {
  if self.state.val.terminated {
    return self.state.val.exit_code.unwrap_or(0)
  }
  self.state.val.terminated = true
  let code = native_finish(self.backend)
  self.state.val.exit_code = Some(code)
  release_event_loop()
  self.state.val.app.exiting(self.state.val.active)
  match self.state.val.active.runtime_failure.val {
    Some(reason) => raise AppError::RuntimeFailed(reason)
    None => code
  }
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
  release_event_loop()
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
    15 => dispatch_proxy_messages(app, active)
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
