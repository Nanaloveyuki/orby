///|
pub struct WebViewHost {
  priv fixed : UInt64
  priv alive : Ref[Bool]
} derive(Debug)

///|
/// Returns the GtkFixed host while its parent window remains alive.
pub fn WebViewHost::native_handle(
  self : WebViewHost,
) -> UInt64 raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  self.fixed
}

///|
pub struct Window {
  priv id_ : @core.WindowId
  priv fixed : UInt64
  priv alive : Ref[Bool]
} derive(Debug)

///|
pub impl Eq for Window with fn equal(self, other) {
  self.id_ == other.id_
}

///|
pub fn Window::id(self : Window) -> @core.WindowId {
  self.id_
}

///|
/// Returns a host for a WebView that must be destroyed before this window.
pub fn Window::webview_host(
  self : Window,
) -> WebViewHost raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  { fixed: self.fixed, alive: self.alive }
}

///|
pub fn Window::is_destroyed(self : Window) -> Bool {
  !self.alive.val
}

///|
/// Returns the GDK monitor currently hosting this window, if one is available.
pub fn Window::current_monitor(
  self : Window,
) -> @core.Monitor? raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  monitor_from_index(native_current_monitor_index(self.fixed))
}

///|
pub fn Window::destroy(self : Window) -> Unit {
  if self.alive.val {
    self.alive.val = false
    native_destroy_window(self.fixed)
  }
}

///|
pub fn Window::set_title(self : Window, title : String) -> Unit {
  if self.alive.val {
    native_set_title(self.fixed, @utf8.encode(title, bom=false))
  }
}

///|
pub fn Window::set_visible(self : Window, visible : Bool) -> Unit {
  if self.alive.val {
    native_set_visible(self.fixed, visible)
  }
}

///|
pub fn Window::set_resizable(self : Window, resizable : Bool) -> Unit {
  if self.alive.val {
    native_set_resizable(self.fixed, resizable)
  }
}

///|
pub fn Window::set_minimized(self : Window, minimized : Bool) -> Unit {
  if self.alive.val {
    native_set_minimized(self.fixed, minimized)
  }
}

///|
pub fn Window::is_minimized(self : Window) -> Bool raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  native_is_minimized(self.fixed)
}

///|
pub fn Window::set_maximized(self : Window, maximized : Bool) -> Unit {
  if self.alive.val {
    native_set_maximized(self.fixed, maximized)
  }
}

///|
pub fn Window::is_maximized(self : Window) -> Bool raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  native_is_maximized(self.fixed)
}

///|
pub fn Window::set_decorated(self : Window, decorated : Bool) -> Unit {
  if self.alive.val {
    native_set_decorated(self.fixed, decorated)
  }
}

///|
/// Requests fullscreen on the native monitor chosen for this window. GTK
/// compositors may apply the request asynchronously.
pub fn Window::set_fullscreen(self : Window, fullscreen : Bool) -> Unit {
  if self.alive.val {
    native_set_fullscreen(self.fixed, fullscreen)
  }
}

///|
/// Returns the fullscreen state currently reported by GDK.
pub fn Window::is_fullscreen(self : Window) -> Bool raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  native_is_fullscreen(self.fixed)
}

///|
/// Sets the physical client-area minimum size. Pass `None` to remove it. If it
/// exceeds the current maximum on an axis, that maximum is raised to match.
pub fn Window::set_min_inner_size(self : Window, size : @core.Size?) -> Unit {
  if self.alive.val {
    match size {
      Some(size) =>
        native_set_min_inner_size(self.fixed, size.width, size.height)
      None => native_set_min_inner_size(self.fixed, 0, 0)
    }
  }
}

///|
/// Sets the physical client-area maximum size. Pass `None` to remove it. If it
/// is below the current minimum on an axis, that minimum is lowered to match.
pub fn Window::set_max_inner_size(self : Window, size : @core.Size?) -> Unit {
  if self.alive.val {
    match size {
      Some(size) =>
        native_set_max_inner_size(self.fixed, size.width, size.height)
      None => native_set_max_inner_size(self.fixed, 0, 0)
    }
  }
}

///|
pub fn Window::inner_size(self : Window) -> @core.Size raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  @core.Size::new(
    width=native_inner_width(self.fixed),
    height=native_inner_height(self.fixed),
  )
}

///|
pub fn Window::set_inner_size(self : Window, size : @core.Size) -> Unit {
  if self.alive.val {
    native_set_inner_size(self.fixed, size.width, size.height)
  }
}

///|
pub fn Window::scale_factor(self : Window) -> Double raise @core.WindowError {
  if !self.alive.val {
    raise @core.WindowError::Destroyed
  }
  native_scale_factor(self.fixed)
}

///|
pub fn Window::set_outer_position(
  self : Window,
  position : @core.Position,
) -> Unit {
  if self.alive.val {
    native_set_outer_position(self.fixed, position.x, position.y)
  }
}

///|
/// Requests application-controlled closure. Handle `CloseRequested` and call
/// `destroy` to accept the request; otherwise it is cancelled.
pub fn Window::request_close(self : Window) -> Unit {
  if self.alive.val {
    native_request_close(self.fixed)
  }
}

///|
pub fn Window::request_redraw(self : Window) -> Unit {
  if self.alive.val {
    native_request_redraw(self.fixed)
  }
}
