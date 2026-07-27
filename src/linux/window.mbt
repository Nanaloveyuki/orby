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
} derive(Eq, Debug)

///|
pub fn Window::id(self : Window) -> @core.WindowId {
  self.id_
}

///|
pub fn Window::webview_host(self : Window) -> WebViewHost {
  { fixed: self.fixed }
}

///|
pub fn Window::destroy(self : Window) -> Unit {
  native_destroy_window(self.fixed)
}

///|
pub fn Window::set_title(self : Window, title : String) -> Unit {
  native_set_title(self.fixed, @utf8.encode(title, bom=false))
}

///|
pub fn Window::request_redraw(self : Window) -> Unit {
  native_request_redraw(self.fixed)
}
