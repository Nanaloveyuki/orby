///|
struct InputApp {
  mut event : WindowEvent?
}

///|
pub impl App for InputApp with fn window_event(self, _active, _id, event) {
  self.event = Some(event)
}

///|
fn test_active() -> ActiveApp {
  {
    backend: NativeBackend::Windows,
    next_window_id: Ref(1),
    runtime_failure: Ref(None),
  }
}

///|
test "input events decode native flags" {
  let app = { event: None }
  let active = test_active()
  dispatch_event(app, active, 7, 1, 65, 16 | 1 | 2 | 32, 0.0, 0.0)
  match app.event {
    Some(KeyInput(event)) => {
      assert_true(event.code == 65)
      assert_true(event.state == Pressed)
      assert_true(event.repeat)
      assert_true(event.modifiers.shift && event.modifiers.control)
    }
    _ => fail("expected key input")
  }
  dispatch_event(app, active, 8, 1, 97, 0, 0.0, 0.0)
  match app.event {
    Some(TextInput(text)) => assert_true(text == "a")
    _ => fail("expected text input")
  }
  dispatch_event(app, active, 9, 1, -12, 48, 0.0, 0.0)
  match app.event {
    Some(PointerMoved(position)) =>
      assert_true(position == Position::new(x=-12, y=48))
    _ => fail("expected pointer motion")
  }
}

///|
test "first runtime failure wins" {
  let failure : Ref[String?] = Ref(None)
  assert_true(record_runtime_failure(failure, "first"))
  assert_false(record_runtime_failure(failure, "second"))
  assert_eq(failure.val, Some("first"))
}
