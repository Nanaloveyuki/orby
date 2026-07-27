///|
struct Smoke {
  mut window : @linux.Window?
}

///|
pub impl @linux.App for Smoke with fn started(self, app) {
  let window = try! app.create_window(
    @core.WindowOptions::new(title="Orby GTK smoke", visible=true),
  )
  self.window = Some(window)
  window.set_visible(false)
  window.set_resizable(false)
  window.set_visible(true)
  window.request_redraw()
  window.request_close()
}

///|
pub impl @linux.App for Smoke with fn window_event(self, app, _id, event) {
  match event {
    @core.WindowEvent::CloseRequested =>
      match self.window {
        Some(window) => window.destroy()
        None => ()
      }
    @core.WindowEvent::Destroyed => {
      match self.window {
        Some(window) => {
          if !window.is_destroyed() {
            abort("Orby GTK smoke expected a destroyed window")
          }
          window.destroy()
          window.set_title("ignored after destruction")
          window.set_visible(false)
          window.set_resizable(true)
          window.request_close()
          window.request_redraw()
        }
        None => ()
      }
      app.exit_with_code(23)
    }
    _ => ()
  }
}

///|
fn main {
  let event_loop = try! @linux.EventLoop::new()
  let app = { window: None }
  let code = event_loop.run_app(app)
  if code != 23 {
    abort("Orby GTK smoke failed with exit code \{code}")
  }
}
