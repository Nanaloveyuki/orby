///|
pub fn[A : App] EventLoop::run_app(self : EventLoop, app : A) -> Int {
  let active = self.active()
  let callback = fn(
    kind : Int,
    id : Int,
    arg0 : Int,
    arg1 : Int,
    argd0 : Double,
    argd1 : Double,
  ) {
    dispatch_event(app, active, kind, id, arg0, arg1, argd0, argd1)
  }
  native_set_event_callback(
    fn(callback, kind, id, arg0, arg1, argd0, argd1) {
      callback(kind, id, arg0, arg1, argd0, argd1)
    },
    callback,
  )
  app.started(active)
  let code = native_run()
  app.exiting(active)
  code
}

///|
fn[A : App] dispatch_event(
  app : A,
  active : ActiveApp,
  kind : Int,
  id : Int,
  arg0 : Int,
  arg1 : Int,
  argd0 : Double,
  argd1 : Double,
) -> Unit {
  match kind {
    14 => app.about_to_wait(active)
    _ => {
      let window_id = @core.WindowId::from_raw(id)
      match kind {
        1 => app.window_event(active, window_id, CloseRequested)
        2 => app.window_event(active, window_id, Destroyed)
        3 =>
          app.window_event(
            active,
            window_id,
            Resized(@core.Size::new(width=arg0, height=arg1)),
          )
        4 => app.window_event(active, window_id, ScaleFactorChanged(argd0))
        5 => app.window_event(active, window_id, FocusChanged(arg0 != 0))
        6 => app.window_event(active, window_id, RedrawRequested)
        7 =>
          app.window_event(
            active,
            window_id,
            KeyInput(
              @core.NativeKeyEvent::new(
                code=arg0,
                state=if (arg1 & 16) != 0 { Pressed } else { Released },
                repeat=(arg1 & 32) != 0,
                modifiers=@core.Modifiers::new(
                  shift=(arg1 & 1) != 0,
                  control=(arg1 & 2) != 0,
                  alt=(arg1 & 4) != 0,
                  meta=(arg1 & 8) != 0,
                ),
              ),
            ),
          )
        8 =>
          match arg0.to_char() {
            Some(character) =>
              app.window_event(
                active,
                window_id,
                TextInput(character.to_string()),
              )
            None => ()
          }
        9 =>
          app.window_event(
            active,
            window_id,
            PointerMoved(@core.Position::new(x=arg0, y=arg1)),
          )
        10 => app.window_event(active, window_id, PointerEntered)
        11 => app.window_event(active, window_id, PointerLeft)
        12 =>
          app.window_event(
            active,
            window_id,
            MouseInput(
              match arg0 {
                1 => @core.MouseButton::Left
                2 => @core.MouseButton::Right
                3 => @core.MouseButton::Middle
                4 => @core.MouseButton::Back
                5 => @core.MouseButton::Forward
                _ => @core.MouseButton::Other(arg0)
              },
              if (arg1 & 16) != 0 {
                Pressed
              } else {
                Released
              },
              @core.Modifiers::new(
                shift=(arg1 & 1) != 0,
                control=(arg1 & 2) != 0,
                alt=(arg1 & 4) != 0,
                meta=(arg1 & 8) != 0,
              ),
            ),
          )
        13 =>
          app.window_event(
            active,
            window_id,
            MouseWheel(
              @core.ScrollDelta::new(x=argd0, y=argd1),
              @core.Modifiers::new(
                shift=(arg1 & 1) != 0,
                control=(arg1 & 2) != 0,
                alt=(arg1 & 4) != 0,
                meta=(arg1 & 8) != 0,
              ),
            ),
          )
        _ => ()
      }
    }
  }
}
