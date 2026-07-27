///|
pub struct WebViewHost {
  priv handle : UInt64
  priv alive : Ref[Bool]
} derive(Debug)

///|
pub fn WebViewHost::native_handle(
  self : WebViewHost,
) -> UInt64 raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  self.handle
}

///|
pub struct Window {
  priv id_ : WindowId
  priv handle : UInt64
  priv alive : Ref[Bool]
  priv backend : NativeBackend
} derive(Debug)

///|
pub impl Eq for Window with fn equal(self, other) {
  self.id_ == other.id_
}

///|
pub fn Window::id(self : Window) -> WindowId {
  self.id_
}

///|
pub fn Window::is_destroyed(self : Window) -> Bool {
  !self.alive.val
}

///|
pub fn Window::webview_host(self : Window) -> WebViewHost raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  { handle: self.handle, alive: self.alive }
}

///|
pub fn Window::current_monitor(self : Window) -> Monitor? raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  monitor_from_index(
    self.backend,
    native_current_monitor_index(self.backend, self.handle),
  )
}

///|
pub fn Window::destroy(self : Window) -> Unit {
  if self.alive.val {
    self.alive.val = false
    native_destroy_window(self.backend, self.handle)
  }
}

///|
pub fn Window::set_title(self : Window, title : String) -> Unit {
  if self.alive.val {
    native_set_title(self.backend, self.handle, @utf8.encode(title, bom=false))
  }
}

///|
pub fn Window::set_visible(self : Window, visible : Bool) -> Unit {
  if self.alive.val {
    native_set_visible(self.backend, self.handle, visible)
  }
}

///|
pub fn Window::set_resizable(self : Window, resizable : Bool) -> Unit {
  if self.alive.val {
    native_set_resizable(self.backend, self.handle, resizable)
  }
}

///|
pub fn Window::set_minimized(self : Window, minimized : Bool) -> Unit {
  if self.alive.val {
    native_set_minimized(self.backend, self.handle, minimized)
  }
}

///|
pub fn Window::is_minimized(self : Window) -> Bool raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  native_is_minimized(self.backend, self.handle)
}

///|
pub fn Window::set_maximized(self : Window, maximized : Bool) -> Unit {
  if self.alive.val {
    native_set_maximized(self.backend, self.handle, maximized)
  }
}

///|
pub fn Window::is_maximized(self : Window) -> Bool raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  native_is_maximized(self.backend, self.handle)
}

///|
pub fn Window::set_decorated(self : Window, decorated : Bool) -> Unit {
  if self.alive.val {
    native_set_decorated(self.backend, self.handle, decorated)
  }
}

///|
pub fn Window::set_fullscreen(self : Window, fullscreen : Bool) -> Unit {
  if self.alive.val {
    native_set_fullscreen(self.backend, self.handle, fullscreen)
  }
}

///|
pub fn Window::set_fullscreen_on(
  self : Window,
  monitor : MonitorId,
) -> Unit raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  if !native_set_fullscreen_on(self.backend, self.handle, monitor.index()) {
    raise WindowError::MonitorUnavailable(monitor)
  }
}

///|
pub fn Window::is_fullscreen(self : Window) -> Bool raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  native_is_fullscreen(self.backend, self.handle)
}

///|
pub fn Window::set_min_inner_size(self : Window, size : Size?) -> Unit {
  if self.alive.val {
    match size {
      Some(value) =>
        native_set_min_inner_size(
          self.backend,
          self.handle,
          value.width,
          value.height,
        )
      None => native_set_min_inner_size(self.backend, self.handle, 0, 0)
    }
  }
}

///|
pub fn Window::set_max_inner_size(self : Window, size : Size?) -> Unit {
  if self.alive.val {
    match size {
      Some(value) =>
        native_set_max_inner_size(
          self.backend,
          self.handle,
          value.width,
          value.height,
        )
      None => native_set_max_inner_size(self.backend, self.handle, 0, 0)
    }
  }
}

///|
pub fn Window::inner_size(self : Window) -> Size raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  Size::new(
    width=native_inner_width(self.backend, self.handle),
    height=native_inner_height(self.backend, self.handle),
  )
}

///|
pub fn Window::set_inner_size(self : Window, size : Size) -> Unit {
  if self.alive.val {
    native_set_inner_size(self.backend, self.handle, size.width, size.height)
  }
}

///|
pub fn Window::scale_factor(self : Window) -> Double raise WindowError {
  if !self.alive.val {
    raise WindowError::Destroyed
  }
  native_scale_factor(self.backend, self.handle)
}

///|
pub fn Window::set_outer_position(self : Window, position : Position) -> Unit {
  if self.alive.val {
    native_set_outer_position(self.backend, self.handle, position.x, position.y)
  }
}

///|
pub fn Window::request_close(self : Window) -> Unit {
  if self.alive.val {
    native_request_close(self.backend, self.handle)
  }
}

///|
pub fn Window::request_redraw(self : Window) -> Unit {
  if self.alive.val {
    native_request_redraw(self.backend, self.handle)
  }
}
