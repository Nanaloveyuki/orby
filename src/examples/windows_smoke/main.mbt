///|
struct Smoke {
  mut window : @windows.Window?
}

///|
pub impl @windows.App for Smoke with fn started(self, app) {
  let window = try! app.create_window(
    @core.WindowOptions::new(title="Orby Win32 smoke", visible=true),
  )
  self.window = Some(window)
  window.set_visible(false)
  window.set_resizable(false)
  window.set_visible(true)
  window.request_redraw()
  window.request_close()
}

///|
pub impl @windows.App for Smoke with fn window_event(self, app, _id, event) {
  match event {
    @core.WindowEvent::CloseRequested =>
      match self.window {
        Some(window) => window.destroy()
        None => ()
      }
    @core.WindowEvent::Destroyed => app.exit_with_code(23)
    _ => ()
  }
}

///|
fn main {
  println("orby windows smoke: initializing")
  let event_loop = try! @windows.EventLoop::new()
  println("orby windows smoke: running")
  let app = { window: None }
  let code = event_loop.run_app(app)
  println("orby windows smoke: exited \{code}")
  if code != 23 {
    abort("Orby Win32 smoke failed with exit code \{code}")
  }
}
