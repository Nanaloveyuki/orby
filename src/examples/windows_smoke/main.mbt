///|
struct Smoke {}

///|
pub impl @windows.App for Smoke with fn started(_self, app) {
  let window = try! app.create_window(
    @core.WindowOptions::new(title="Orby Win32 smoke", visible=true),
  )
  window.request_redraw()
  window.destroy()
  app.exit()
}

///|
fn main {
  println("orby windows smoke: initializing")
  let event_loop = try! @windows.EventLoop::new()
  println("orby windows smoke: running")
  let app = Smoke::{  }
  let code = event_loop.run_app(app)
  println("orby windows smoke: exited \{code}")
  if code != 0 {
    abort("Orby Win32 smoke failed with exit code \{code}")
  }
}
