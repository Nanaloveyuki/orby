///|
pub struct WebViewHost {
  priv hwnd : UInt64
} derive(Eq, Debug)

///|
pub fn WebViewHost::native_handle(self : WebViewHost) -> UInt64 {
  self.hwnd
}

///|
pub struct Window {
  priv id_ : @core.WindowId
  priv hwnd : UInt64
} derive(Eq, Debug)

///|
pub fn Window::id(self : Window) -> @core.WindowId {
  self.id_
}

///|
pub fn Window::webview_host(self : Window) -> WebViewHost {
  { hwnd: self.hwnd }
}

///|
pub fn Window::destroy(self : Window) -> Unit {
  native_destroy_window(self.hwnd)
}

///|
pub fn Window::set_title(self : Window, title : String) -> Unit {
  native_set_title(self.hwnd, @utf8.encode(title, bom=false))
}

///|
pub fn Window::set_visible(self : Window, visible : Bool) -> Unit {
  native_set_visible(self.hwnd, visible)
}

///|
pub fn Window::set_resizable(self : Window, resizable : Bool) -> Unit {
  native_set_resizable(self.hwnd, resizable)
}

///|
/// Requests application-controlled closure. Handle `CloseRequested` and call
/// `destroy` to accept the request; otherwise it is cancelled.
pub fn Window::request_close(self : Window) -> Unit {
  native_request_close(self.hwnd)
}

///|
pub fn Window::request_redraw(self : Window) -> Unit {
  native_request_redraw(self.hwnd)
}
