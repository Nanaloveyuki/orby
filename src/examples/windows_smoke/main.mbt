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
  let initial_size = try! window.inner_size()
  if initial_size != @core.Size::new(width=800, height=600) {
    abort("Orby Win32 smoke expected an 800x600 client area")
  }
  if (try! window.scale_factor()) <= 0.0 {
    abort("Orby Win32 smoke expected a positive scale factor")
  }
  window.set_inner_size(@core.Size::new(width=640, height=480))
  window.set_outer_position(@core.Position::new(x=40, y=40))
  window.set_minimized(false)
  window.set_maximized(false)
  if (try! window.is_minimized()) || (try! window.is_maximized()) {
    abort("Orby Win32 smoke expected a restored window")
  }
  window.set_decorated(false)
  window.set_decorated(true)
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
    @core.WindowEvent::Destroyed => {
      match self.window {
        Some(window) => {
          if !window.is_destroyed() {
            abort("Orby Win32 smoke expected a destroyed window")
          }
          window.destroy()
          window.set_title("ignored after destruction")
          window.set_visible(false)
          window.set_resizable(true)
          window.set_inner_size(@core.Size::new(width=320, height=240))
          window.set_outer_position(@core.Position::new(x=0, y=0))
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
