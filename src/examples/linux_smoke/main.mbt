///|
struct Smoke {}

///|
pub impl @linux.App for Smoke with fn started(_self, app) {
  let window = try! app.create_window(
    @core.WindowOptions::new(title="Orby GTK smoke", visible=true),
  )
  window.request_redraw()
  window.destroy()
  app.exit()
}

///|
fn main {
  let event_loop = try! @linux.EventLoop::new()
  let app = Smoke::{  }
  let code = event_loop.run_app(app)
  if code != 0 {
    abort("Orby GTK smoke failed with exit code \{code}")
  }
}
