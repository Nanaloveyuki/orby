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
pub fn EventLoop::EventLoop() -> EventLoop {
  try! EventLoop::new()
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
  { id_: @core.WindowId::from_raw(id), fixed }
}

///|
pub fn ActiveApp::exit(_self : ActiveApp) -> Unit {
  native_exit()
}

///|
pub fn[A : App] EventLoop::run_app(self : EventLoop, app : A) -> Int {
  let active = self.active()
  let callback = fn(
    kind : Int,
    id : Int,
    arg0 : Int,
    arg1 : Int,
    argd : Double,
  ) {
    dispatch_event(app, active, kind, id, arg0, arg1, argd)
  }
  native_set_event_callback(
    fn(callback, kind, id, arg0, arg1, argd) {
      callback(kind, id, arg0, arg1, argd)
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
  argd : Double,
) -> Unit {
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
    4 => app.window_event(active, window_id, ScaleFactorChanged(argd))
    5 => app.window_event(active, window_id, FocusChanged(arg0 != 0))
    6 => app.window_event(active, window_id, RedrawRequested)
    _ => ()
  }
  app.about_to_wait(active)
}
