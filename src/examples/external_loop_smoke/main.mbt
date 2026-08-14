///|
struct ExternalSmoke {
  mut exiting_called : Bool
}

///|
pub impl @orby.App for ExternalSmoke with fn started(_self, app) {
  app.exit_with_code(23)
}

///|
pub impl @orby.App for ExternalSmoke with fn exiting(self, _app) {
  self.exiting_called = true
}

///|
fn main raise {
  let event_loop = @orby.EventLoop::new()
  try ignore(@orby.EventLoop::new()) catch {
    @orby.InitError::AlreadyActive => ()
    _ => abort("orby external loop: unexpected concurrent-loop error")
  } noraise {
    _ => abort("orby external loop: concurrent EventLoop was accepted")
  }
  let app = { exiting_called: false }
  let external = event_loop.start_external_app(app)
  let code = match external.poll(timeout=0) {
    @orby.ExternalPoll::Continue =>
      abort("orby external loop: exit was not observed")
    @orby.ExternalPoll::Exited(code) => code
  }
  if code != 23 || !app.exiting_called {
    abort("orby external loop: terminal result was not preserved")
  }
  let next_event_loop = @orby.EventLoop::new()
  let next_app = { exiting_called: false }
  let next_external = next_event_loop.start_external_app(next_app)
  let next_code = match next_external.poll(timeout=0) {
    @orby.ExternalPoll::Continue =>
      abort("orby external loop: sequential exit was not observed")
    @orby.ExternalPoll::Exited(code) => code
  }
  if next_code != 23 || !next_app.exiting_called {
    abort("orby external loop: sequential EventLoop failed")
  }
  println("orby external loop smoke: passed")
}
