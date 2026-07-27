///|
struct Smoke {
  mut window : @windows.Window?
  mut view : @moonview.WebView?
  mut passed : Bool
}

///|
fn Smoke::destroy_host(self : Smoke) -> Unit {
  match self.view {
    Some(view) => ignore(view.destroy())
    None => ()
  }
  self.view = None
  match self.window {
    Some(window) => window.destroy()
    None => ()
  }
}

///|
fn Smoke::respond_protocol(
  self : Smoke,
  request : @moonview.ProtocolRequest,
) -> Unit {
  match self.view {
    Some(view) =>
      ignore(
        view.respond_protocol(
          request.id,
          @moonview.ProtocolResponse::new(
            status=200,
            headers=[
              @moonview.HttpHeader::new(name="Content-Type", value="text/html"),
            ],
            body=@utf8.encode(
              (
                #|<!doctype html><meta charset="utf-8"><title>Orby MoonView smoke</title>
                #|<script>
                #|window.moonview.onmessage = message => {
                #|  const value = typeof message === "string" ? message : message.data;
                #|  if (value === "host-ping") window.moonview.postMessage("page-ack");
                #|};
                #|window.moonview.postMessage("page-ready");
                #|</script>
              )[:],
              bom=false,
            ),
          ),
        ),
      )
    None => ()
  }
}

///|
fn Smoke::handle_event(self : Smoke, event : @moonview.WebViewEvent) -> Unit {
  match event {
    @moonview.WebViewEvent::Ready => println("orby moonview windows: ready")
    @moonview.WebViewEvent::ProtocolRequest(request) =>
      self.respond_protocol(request)
    @moonview.WebViewEvent::PageMessage("page-ready") =>
      match self.view {
        Some(view) => ignore(view.post_message("host-ping"))
        None => ()
      }
    @moonview.WebViewEvent::PageMessage("page-ack") =>
      match self.view {
        Some(view) => ignore(view.eval("40 + 2", "orby-answer"))
        None => ()
      }
    @moonview.WebViewEvent::ScriptResult("orby-answer", "42") => {
      self.passed = true
      println("orby moonview windows: passed")
      self.destroy_host()
    }
    @moonview.WebViewEvent::CreationFailed(_error) => {
      println("orby moonview windows: creation failed")
      self.destroy_host()
    }
    @moonview.WebViewEvent::ScriptFailed(request_id, _error) => {
      println("orby moonview windows: script failed \{request_id}")
      self.destroy_host()
    }
    _ => ()
  }
}

///|
pub impl @windows.App for Smoke with fn started(self, app) {
  let window = try! app.create_window(
    @core.WindowOptions::new(title="Orby MoonView WebView2 smoke"),
  )
  let host = window.webview_host().native_handle()
  self.window = Some(window)
  let options = @moonview.WebViewOptions::new(
    bounds=@moonview.Rect::new(x=0, y=0, width=800, height=600),
    initial_url="orby://app/index.html",
    initialization_script=(
      #|window.moonview.onmessage = function (message) {
      #|  if (message === "host-ping") window.moonview.postMessage("page-ack");
      #|};
    ),
    on_event=event => self.handle_event(event),
  )
  match @moonview.WebView::create(host, options) {
    Ok(view) => self.view = Some(view)
    Err(_error) => {
      println("orby moonview windows: create rejected")
      self.destroy_host()
    }
  }
}

///|
pub impl @windows.App for Smoke with fn window_event(self, app, _id, event) {
  match event {
    @core.WindowEvent::Resized(size) =>
      match self.view {
        Some(view) =>
          ignore(
            view.set_bounds(
              @moonview.Rect::new(
                x=0,
                y=0,
                width=size.width,
                height=size.height,
              ),
            ),
          )
        None => ()
      }
    @core.WindowEvent::CloseRequested => self.destroy_host()
    @core.WindowEvent::Destroyed => app.exit()
    _ => ()
  }
}

///|
fn main {
  match @moonview.register_custom_scheme("orby") {
    Ok(_) => ()
    Err(_error) => abort("orby moonview windows: scheme registration failed")
  }
  let app = { window: None, view: None, passed: false }
  let event_loop = try! @windows.EventLoop::new()
  let code = event_loop.run_app(app)
  if code != 0 || !app.passed {
    abort("orby moonview windows: smoke failed")
  }
}
