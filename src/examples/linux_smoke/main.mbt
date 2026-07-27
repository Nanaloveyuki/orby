///|
struct Smoke {
  mut window : @linux.Window?
  mut constraint_phase : Int
}

///|
pub impl @linux.App for Smoke with fn started(self, app) {
  let window = try! app.create_window(
    @core.WindowOptions::new(title="Orby GTK smoke", visible=true),
  )
  self.window = Some(window)
  let initial_size = try! window.inner_size()
  if initial_size != @core.Size::new(width=800, height=600) {
    abort("Orby GTK smoke expected an 800x600 client area")
  }
  if (try! window.scale_factor()) <= 0.0 {
    abort("Orby GTK smoke expected a positive scale factor")
  }
  window.set_inner_size(@core.Size::new(width=640, height=480))
  window.set_min_inner_size(Some(@core.Size::new(width=400, height=300)))
  window.set_max_inner_size(Some(@core.Size::new(width=640, height=480)))
}

///|
fn Smoke::finish_window_setup(_self : Smoke, window : @linux.Window) -> Unit {
  window.set_min_inner_size(None)
  window.set_max_inner_size(None)
  window.set_outer_position(@core.Position::new(x=40, y=40))
  window.set_minimized(false)
  window.set_maximized(false)
  if (try! window.is_minimized()) || (try! window.is_maximized()) {
    abort("Orby GTK smoke expected a restored window")
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
pub impl @linux.App for Smoke with fn window_event(self, app, _id, event) {
  match event {
    @core.WindowEvent::Resized(size) =>
      match self.window {
        Some(window) =>
          if self.constraint_phase == 1 {
            if size.width < 400 || size.height < 300 {
              abort(
                "Orby GTK smoke expected the minimum client size to be enforced",
              )
            }
            window.set_inner_size(@core.Size::new(width=2000, height=2000))
            self.constraint_phase = 2
          } else if self.constraint_phase == 2 {
            if size.width > 640 || size.height > 480 {
              abort(
                "Orby GTK smoke expected the maximum client size to be enforced",
              )
            }
            self.finish_window_setup(window)
            self.constraint_phase = 3
          }
        None => ()
      }
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
pub impl @linux.App for Smoke with fn about_to_wait(self, _app) {
  if self.constraint_phase == 0 {
    match self.window {
      Some(window) => {
        window.set_inner_size(@core.Size::new(width=1, height=1))
        self.constraint_phase = 1
      }
      None => ()
    }
  }
}

///|
fn main {
  let event_loop = try! @linux.EventLoop::new()
  let app = { window: None, constraint_phase: 0 }
  let code = event_loop.run_app(app)
  if code != 23 {
    abort("Orby GTK smoke failed with exit code \{code}")
  }
}
