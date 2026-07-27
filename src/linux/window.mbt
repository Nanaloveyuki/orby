///|
pub struct WebViewHost {
  priv fixed : UInt64
} derive(Eq, Debug)

///|
pub fn WebViewHost::native_handle(self : WebViewHost) -> UInt64 {
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
pub fn Window::webview_host(self : Window) -> WebViewHost {
  { fixed: self.fixed }
}

///|
pub fn Window::is_destroyed(self : Window) -> Bool {
  !self.alive.val
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
