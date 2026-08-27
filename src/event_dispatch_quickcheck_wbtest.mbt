///|
struct KeyFlagApp {
  mut key_event : WindowEvent?
}

///|
pub impl App for KeyFlagApp with fn window_event(self, _active, _id, event) {
  self.key_event = Some(event)
}

///|
fn key_flag_test_active() -> ActiveApp {
  {
    backend: NativeBackend::Windows,
    proxy_generation: 1UL,
    next_window_id: Ref(1),
    runtime_failure: Ref(None),
  }
}

///|
test "quickcheck: key event flags decode independently" {
  @quickcheck.check(
    (input : (Int, Int, Int)) => {
      let (code, flags, raw_id) = input
      let app : KeyFlagApp = { key_event: None }
      dispatch_event(
        app,
        key_flag_test_active(),
        7,
        raw_id,
        code,
        flags,
        0.0,
        0.0,
      )
      match app.key_event {
        Some(KeyInput(event)) =>
          event.code == code &&
          event.state == (if (flags & 16) != 0 { Pressed } else { Released }) &&
          event.repeat == ((flags & 32) != 0) &&
          event.modifiers.shift == ((flags & 1) != 0) &&
          event.modifiers.control == ((flags & 2) != 0) &&
          event.modifiers.alt == ((flags & 4) != 0) &&
          event.modifiers.meta == ((flags & 8) != 0)
        _ => false
      }
    },
    count=250,
    max_size=2048,
    max_shrinks=200,
    seed=2026082509,
  )
}
