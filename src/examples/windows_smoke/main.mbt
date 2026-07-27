///|
struct Smoke {
  mut window : @orby.Window?
  mut control_flow_switched : Bool
}

///|
pub impl @orby.App for Smoke with fn started(self, app) {
  app.set_control_flow(@orby.ControlFlow::Poll)
  let window = try! app.create_window(
    @orby.WindowOptions::new(title="Orby Win32 smoke", visible=true),
  )
  self.window = Some(window)
  match (try! window.current_monitor()) {
    Some(monitor) =>
      if monitor.width < 1 || monitor.height < 1 || monitor.scale_factor <= 0.0 {
        abort("Orby Win32 smoke expected a valid current monitor")
      }
    None => abort("Orby Win32 smoke expected a current monitor")
  }
  let initial_size = try! window.inner_size()
  if initial_size != @orby.Size::new(width=800, height=600) {
    abort("Orby Win32 smoke expected an 800x600 client area")
  }
  if (try! window.scale_factor()) <= 0.0 {
    abort("Orby Win32 smoke expected a positive scale factor")
  }
  window.set_inner_size(@orby.Size::new(width=640, height=480))
  window.set_min_inner_size(Some(@orby.Size::new(width=400, height=300)))
  window.set_max_inner_size(Some(@orby.Size::new(width=640, height=480)))
  window.set_inner_size(@orby.Size::new(width=1, height=1))
  let constrained_size = try! window.inner_size()
  if constrained_size.width < 400 || constrained_size.height < 300 {
    abort("Orby Win32 smoke expected the minimum client size to be enforced")
  }
  window.set_inner_size(@orby.Size::new(width=2000, height=2000))
  let bounded_size = try! window.inner_size()
  if bounded_size.width > 640 || bounded_size.height > 480 {
    abort("Orby Win32 smoke expected the maximum client size to be enforced")
  }
  window.set_min_inner_size(None)
  window.set_max_inner_size(None)
  window.set_outer_position(@orby.Position::new(x=40, y=40))
  window.set_minimized(false)
  window.set_maximized(false)
  if (try! window.is_minimized()) || (try! window.is_maximized()) {
    abort("Orby Win32 smoke expected a restored window")
  }
  window.set_decorated(false)
  window.set_decorated(true)
  window.set_fullscreen(true)
  if !(try! window.is_fullscreen()) {
    abort("Orby Win32 smoke expected managed fullscreen state")
  }
  window.set_fullscreen(false)
  if (try! window.is_fullscreen()) {
    abort("Orby Win32 smoke expected a restored window")
  }
  window.set_visible(false)
  window.set_resizable(false)
  window.set_visible(true)
  window.request_redraw()
}

///|
pub impl @orby.App for Smoke with fn window_event(self, app, _id, event) {
  match event {
    @orby.WindowEvent::CloseRequested =>
      match self.window {
        Some(window) => window.destroy()
        None => ()
      }
    @orby.WindowEvent::Destroyed => {
      if !self.control_flow_switched {
        abort("Orby Win32 smoke expected a control-flow callback")
      }
      match self.window {
        Some(window) => {
          if !window.is_destroyed() {
            abort("Orby Win32 smoke expected a destroyed window")
          }
          window.destroy()
          window.set_title("ignored after destruction")
          window.set_visible(false)
          window.set_resizable(true)
          window.set_inner_size(@orby.Size::new(width=320, height=240))
          window.set_outer_position(@orby.Position::new(x=0, y=0))
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
pub impl @orby.App for Smoke with fn about_to_wait(self, app) {
  if !self.control_flow_switched {
    self.control_flow_switched = true
    app.set_control_flow(@orby.ControlFlow::Wait)
    match self.window {
      Some(window) => window.request_close()
      None => ()
    }
  }
}

///|
fn main raise {
  println("orby windows smoke: initializing")
  let event_loop = @orby.EventLoop::new()
  let monitors = event_loop.available_monitors()
  if monitors.length() < 1 {
    abort("Orby Win32 smoke expected at least one monitor")
  }
  for monitor in monitors {
    match event_loop.monitor(monitor.id) {
      Some(resolved) =>
        if resolved != monitor {
          abort("Orby Win32 smoke expected monitor IDs to resolve")
        }
      None => abort("Orby Win32 smoke expected monitor IDs to resolve")
    }
  }
  match event_loop.primary_monitor() {
    Some(monitor) =>
      if monitor.width < 1 || monitor.height < 1 || monitor.scale_factor <= 0.0 {
        abort("Orby Win32 smoke expected a valid primary monitor")
      }
    None => abort("Orby Win32 smoke expected a primary monitor")
  }
  println("orby windows smoke: running")
  let app = { window: None, control_flow_switched: false }
  let code = event_loop.run_app(app)
  println("orby windows smoke: exited \{code}")
  if code != 23 {
    abort("Orby Win32 smoke failed with exit code \{code}")
  }
}
