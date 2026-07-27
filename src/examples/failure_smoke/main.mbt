///|
enum FailureMode {
  Startup
  Runtime
}

///|
struct FailureApp {
  mode : FailureMode
  mut exiting_called : Bool
}

///|
pub impl @orby.App for FailureApp with fn started(self, app) {
  match self.mode {
    Startup => raise @orby.AppError::StartupFailed("startup failure")
    Runtime => app.set_control_flow(@orby.ControlFlow::Poll)
  }
}

///|
pub impl @orby.App for FailureApp with fn about_to_wait(self, app) {
  match self.mode {
    Startup => ()
    Runtime => app.fail("runtime failure")
  }
}

///|
pub impl @orby.App for FailureApp with fn exiting(self, _app) {
  self.exiting_called = true
}

///|
fn assert_failure(
  mode : FailureMode,
  expected : String,
) -> Unit raise @orby.InitError {
  let event_loop = @orby.EventLoop::new()
  let app = { mode, exiting_called: false }
  try event_loop.run_app(app) catch {
    @orby.AppError::StartupFailed(reason) =>
      if expected != reason {
        abort("unexpected startup failure: \{reason}")
      }
    @orby.AppError::RuntimeFailed(reason) =>
      if expected != reason {
        abort("unexpected runtime failure: \{reason}")
      }
  } noraise {
    _ => abort("expected a checked application failure")
  }
  if !app.exiting_called {
    abort("Orby must call exiting exactly once")
  }
}

///|
fn main raise {
  assert_failure(Startup, "startup failure")
  assert_failure(Runtime, "runtime failure")
  println("orby failure lifecycle smoke: passed")
}
