///|
/// A thread-safe sender for byte messages delivered to App::proxy_message.
///
/// The native queue copies every message, so callers may release the source
/// bytes immediately. It accepts at most 1 MiB per message and 8 MiB in total.
pub struct EventLoopProxy {
  priv backend : NativeBackend
  priv generation : UInt64
} derive(Debug)

///|
/// A rejected event-loop proxy submission.
pub(all) enum ProxyError {
  Closed
  MessageTooLarge
  QueueFull
} derive(Eq, Debug)

///|
/// Returns a sender that can be moved to a worker thread.
///
/// Only byte messages cross the thread boundary. Their handlers still run on
/// Orby's UI thread through App::proxy_message.
pub fn EventLoop::proxy(self : EventLoop) -> EventLoopProxy {
  { backend: self.backend, generation: self.proxy_generation }
}

///|
/// Returns a sender associated with this running application.
pub fn ActiveApp::proxy(self : ActiveApp) -> EventLoopProxy {
  { backend: self.backend, generation: self.proxy_generation }
}

///|
/// Returns whether this event-loop proxy can no longer accept messages.
pub fn EventLoopProxy::is_closed(self : EventLoopProxy) -> Bool {
  !native_proxy_is_open(self.backend, self.generation)
}

///|
/// Copies a byte message into the native queue and wakes the UI event loop.
///
/// A successful submission is delivered in FIFO order. Delivery stops when the
/// event loop exits; callers must handle Closed as a normal shutdown result.
pub fn EventLoopProxy::post(
  self : EventLoopProxy,
  message : Bytes,
) -> Result[Unit, ProxyError] {
  if self.is_closed() {
    return Err(Closed)
  }
  proxy_post_result(
    native_post_proxy_message(self.backend, self.generation, message),
  )
}

///|
fn proxy_post_result(status : Int) -> Result[Unit, ProxyError] {
  match status {
    1 => Ok(())
    2 => Err(MessageTooLarge)
    3 => Err(QueueFull)
    _ => Err(Closed)
  }
}

///|
fn take_proxy_message(backend : NativeBackend) -> Bytes? {
  let length : Ref[Int] = Ref(-1)
  let message = native_take_proxy_message(backend, length)
  if length.val < 0 {
    None
  } else {
    Some(message)
  }
}

///|
fn[A : App] dispatch_proxy_messages(app : A, active : ActiveApp) -> Unit {
  let mut delivered = 0
  while delivered < 256 {
    match take_proxy_message(active.backend) {
      None => break
      Some(message) => {
        app.proxy_message(active, message)
        delivered = delivered + 1
      }
    }
  }
}
