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

///|
pub fn[A : App] EventLoop::run_app(self : EventLoop, app : A) -> Int {
  let active = self.active()
  let callback = fn(
    kind : Int,
    id : Int,
    arg0 : Int,
    arg1 : Int,
    argd0 : Double,
    argd1 : Double,
  ) {
    dispatch_event(app, active, kind, id, arg0, arg1, argd0, argd1)
  }
  native_set_event_callback(
    fn(callback, kind, id, arg0, arg1, argd0, argd1) {
      callback(kind, id, arg0, arg1, argd0, argd1)
    },
    callback,
  )
  app.started(active)
  let code = native_run()
  app.exiting(active)
  code
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
      let window_id = @core.WindowId::from_raw(id)
      match kind {
        1 => app.window_event(active, window_id, CloseRequested)
        2 => app.window_event(active, window_id, Destroyed)
        3 =>
          app.window_event(
            active,
            window_id,
            Resized(@core.Size::new(width=arg0, height=arg1)),
          )
        4 => app.window_event(active, window_id, ScaleFactorChanged(argd0))
        5 => app.window_event(active, window_id, FocusChanged(arg0 != 0))
        6 => app.window_event(active, window_id, RedrawRequested)
        7 =>
          app.window_event(
            active,
            window_id,
            KeyInput(
              @core.NativeKeyEvent::new(
                code=arg0,
                state=if (arg1 & 16) != 0 { Pressed } else { Released },
                repeat=(arg1 & 32) != 0,
                modifiers=@core.Modifiers::new(
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
            PointerMoved(@core.Position::new(x=arg0, y=arg1)),
          )
        10 => app.window_event(active, window_id, PointerEntered)
        11 => app.window_event(active, window_id, PointerLeft)
        12 =>
          app.window_event(
            active,
            window_id,
            MouseInput(
              match arg0 {
                1 => @core.MouseButton::Left
                2 => @core.MouseButton::Right
                3 => @core.MouseButton::Middle
                4 => @core.MouseButton::Back
                5 => @core.MouseButton::Forward
                _ => @core.MouseButton::Other(arg0)
              },
              if (arg1 & 16) != 0 {
                Pressed
              } else {
                Released
              },
              @core.Modifiers::new(
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
              @core.ScrollDelta::new(x=argd0, y=argd1),
              @core.Modifiers::new(
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
