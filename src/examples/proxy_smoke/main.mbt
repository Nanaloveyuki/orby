///|
struct ProxySmoke {
  mut delivered : Int
  mut exiting_called : Bool
}

///|
pub impl @orby.App for ProxySmoke with fn started(_self, app) {
  let proxy = app.proxy()
  match proxy.post(@utf8.encode("first")) {
    Ok(_) => ()
    Err(_) => app.fail("first proxy submission failed")
  }
  match proxy.post(@utf8.encode("second")) {
    Ok(_) => ()
    Err(_) => app.fail("second proxy submission failed")
  }
}

///|
pub impl @orby.App for ProxySmoke with fn proxy_message(self, app, message) {
  let expected = if self.delivered == 0 { "first" } else { "second" }
  if @utf8.decode_lossy(message) != expected {
    app.fail("proxy delivered an unexpected message")
    return
  }
  self.delivered = self.delivered + 1
  if self.delivered == 2 {
    app.exit()
  }
}

///|
pub impl @orby.App for ProxySmoke with fn exiting(self, _app) {
  self.exiting_called = true
}

///|
fn main raise {
  let event_loop = @orby.EventLoop::new()
  let app = { delivered: 0, exiting_called: false }
  let code = event_loop.run_app(app)
  if code != 0 || app.delivered != 2 || !app.exiting_called {
    abort("orby proxy smoke failed")
  }
  let proxy = event_loop.proxy()
  if !proxy.is_closed() {
    abort("orby proxy must close with its event loop")
  }
  match proxy.post(@utf8.encode("after exit")) {
    Err(@orby.ProxyError::Closed) => ()
    _ => abort("closed proxy accepted a message")
  }
  let next_event_loop = @orby.EventLoop::new()
  if !proxy.is_closed() {
    abort("a prior proxy must not attach to a later event loop")
  }
  let next_app = { delivered: 0, exiting_called: false }
  let next_code = next_event_loop.run_app(next_app)
  if next_code != 0 || next_app.delivered != 2 || !next_app.exiting_called {
    abort("second proxy smoke loop failed")
  }
  println("orby proxy smoke: passed")
}
