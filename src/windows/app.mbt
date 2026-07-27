///|
pub(open) trait App {
  fn started(Self, ActiveApp) -> Unit = _
  fn window_event(Self, ActiveApp, @core.WindowId, @core.WindowEvent) -> Unit = _
  fn about_to_wait(Self, ActiveApp) -> Unit = _
  fn exiting(Self, ActiveApp) -> Unit = _
}

///|
impl App with fn started(_self, _app) {
  ()
}

///|
impl App with fn window_event(_self, _app, _id, _event) {
  ()
}

///|
impl App with fn about_to_wait(_self, _app) {
  ()
}

///|
impl App with fn exiting(_self, _app) {
  ()
}
