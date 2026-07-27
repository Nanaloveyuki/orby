///|
struct InputApp {
  mut event : @core.WindowEvent?
}

///|
pub impl App for InputApp with fn window_event(self, _active, _id, event) {
  self.event = Some(event)
}

///|
test "key input decodes native flags" {
  let app = { event: None }
  let active : ActiveApp = { next_window_id: Ref(1) }
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
}

///|
test "text pointer button and scroll decode" {
  let app = { event: None }
  let active : ActiveApp = { next_window_id: Ref(1) }
  dispatch_event(app, active, 8, 1, 97, 0, 0.0, 0.0)
  match app.event {
    Some(TextInput(text)) => assert_true(text == "a")
    _ => fail("expected text input")
  }
  dispatch_event(app, active, 9, 1, -12, 48, 0.0, 0.0)
  match app.event {
    Some(PointerMoved(position)) =>
      assert_true(position == @core.Position::new(x=-12, y=48))
    _ => fail("expected pointer motion")
  }
  dispatch_event(app, active, 12, 1, 4, 16 | 4, 0.0, 0.0)
  match app.event {
    Some(MouseInput(Back, Pressed, modifiers)) => assert_true(modifiers.alt)
    _ => fail("expected back button input")
  }
  dispatch_event(app, active, 13, 1, 0, 8, 1.5, -2.0)
  match app.event {
    Some(MouseWheel(delta, modifiers)) => {
      assert_true(delta == @core.ScrollDelta::new(x=1.5, y=-2.0))
      assert_true(modifiers.meta)
    }
    _ => fail("expected scroll input")
  }
}
