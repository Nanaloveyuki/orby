///|
priv enum NativeBackend {
  Windows
  Linux
} derive(Debug)

///|
fn initialize_backend() -> NativeBackend raise InitError {
  if @windows.initialize() {
    NativeBackend::Windows
  } else if @linux.initialize() {
    NativeBackend::Linux
  } else {
    raise InitError::PlatformFailure(
      "Orby requires a Win32 STA UI thread or a GTK3 graphical session",
    )
  }
}

///|
fn native_create_window(
  backend : NativeBackend,
  title : Bytes,
  width : Int,
  height : Int,
  visible : Bool,
  resizable : Bool,
  id : Int,
) -> UInt64 {
  match backend {
    Windows =>
      @windows.create_window(title, width, height, visible, resizable, id)
    Linux => @linux.create_window(title, width, height, visible, resizable, id)
  }
}

///|
fn native_destroy_window(backend : NativeBackend, handle : UInt64) -> Unit {
  match backend {
    Windows => @windows.destroy_window(handle)
    Linux => @linux.destroy_window(handle)
  }
}

///|
fn native_set_title(
  backend : NativeBackend,
  handle : UInt64,
  title : Bytes,
) -> Unit {
  match backend {
    Windows => @windows.set_title(handle, title)
    Linux => @linux.set_title(handle, title)
  }
}

///|
fn native_request_redraw(backend : NativeBackend, handle : UInt64) -> Unit {
  match backend {
    Windows => @windows.request_redraw(handle)
    Linux => @linux.request_redraw(handle)
  }
}

///|
fn native_set_visible(
  backend : NativeBackend,
  handle : UInt64,
  visible : Bool,
) -> Unit {
  match backend {
    Windows => @windows.set_visible(handle, visible)
    Linux => @linux.set_visible(handle, visible)
  }
}

///|
fn native_set_resizable(
  backend : NativeBackend,
  handle : UInt64,
  resizable : Bool,
) -> Unit {
  match backend {
    Windows => @windows.set_resizable(handle, resizable)
    Linux => @linux.set_resizable(handle, resizable)
  }
}

///|
fn native_set_minimized(
  backend : NativeBackend,
  handle : UInt64,
  minimized : Bool,
) -> Unit {
  match backend {
    Windows => @windows.set_minimized(handle, minimized)
    Linux => @linux.set_minimized(handle, minimized)
  }
}

///|
fn native_is_minimized(backend : NativeBackend, handle : UInt64) -> Bool {
  match backend {
    Windows => @windows.is_minimized(handle)
    Linux => @linux.is_minimized(handle)
  }
}

///|
fn native_set_maximized(
  backend : NativeBackend,
  handle : UInt64,
  maximized : Bool,
) -> Unit {
  match backend {
    Windows => @windows.set_maximized(handle, maximized)
    Linux => @linux.set_maximized(handle, maximized)
  }
}

///|
fn native_is_maximized(backend : NativeBackend, handle : UInt64) -> Bool {
  match backend {
    Windows => @windows.is_maximized(handle)
    Linux => @linux.is_maximized(handle)
  }
}

///|
fn native_set_decorated(
  backend : NativeBackend,
  handle : UInt64,
  decorated : Bool,
) -> Unit {
  match backend {
    Windows => @windows.set_decorated(handle, decorated)
    Linux => @linux.set_decorated(handle, decorated)
  }
}

///|
fn native_set_fullscreen(
  backend : NativeBackend,
  handle : UInt64,
  fullscreen : Bool,
) -> Unit {
  match backend {
    Windows => @windows.set_fullscreen(handle, fullscreen)
    Linux => @linux.set_fullscreen(handle, fullscreen)
  }
}

///|
fn native_set_fullscreen_on(
  backend : NativeBackend,
  handle : UInt64,
  monitor : Int,
) -> Bool {
  match backend {
    Windows => @windows.set_fullscreen_on(handle, monitor)
    Linux => @linux.set_fullscreen_on(handle, monitor)
  }
}

///|
fn native_is_fullscreen(backend : NativeBackend, handle : UInt64) -> Bool {
  match backend {
    Windows => @windows.is_fullscreen(handle)
    Linux => @linux.is_fullscreen(handle)
  }
}

///|
fn native_set_min_inner_size(
  backend : NativeBackend,
  handle : UInt64,
  width : Int,
  height : Int,
) -> Unit {
  match backend {
    Windows => @windows.set_min_inner_size(handle, width, height)
    Linux => @linux.set_min_inner_size(handle, width, height)
  }
}

///|
fn native_set_max_inner_size(
  backend : NativeBackend,
  handle : UInt64,
  width : Int,
  height : Int,
) -> Unit {
  match backend {
    Windows => @windows.set_max_inner_size(handle, width, height)
    Linux => @linux.set_max_inner_size(handle, width, height)
  }
}

///|
fn native_set_inner_size(
  backend : NativeBackend,
  handle : UInt64,
  width : Int,
  height : Int,
) -> Unit {
  match backend {
    Windows => @windows.set_inner_size(handle, width, height)
    Linux => @linux.set_inner_size(handle, width, height)
  }
}

///|
fn native_inner_width(backend : NativeBackend, handle : UInt64) -> Int {
  match backend {
    Windows => @windows.inner_width(handle)
    Linux => @linux.inner_width(handle)
  }
}

///|
fn native_inner_height(backend : NativeBackend, handle : UInt64) -> Int {
  match backend {
    Windows => @windows.inner_height(handle)
    Linux => @linux.inner_height(handle)
  }
}

///|
fn native_scale_factor(backend : NativeBackend, handle : UInt64) -> Double {
  match backend {
    Windows => @windows.scale_factor(handle)
    Linux => @linux.scale_factor(handle)
  }
}

///|
fn native_set_outer_position(
  backend : NativeBackend,
  handle : UInt64,
  x : Int,
  y : Int,
) -> Unit {
  match backend {
    Windows => @windows.set_outer_position(handle, x, y)
    Linux => @linux.set_outer_position(handle, x, y)
  }
}

///|
fn native_request_close(backend : NativeBackend, handle : UInt64) -> Unit {
  match backend {
    Windows => @windows.request_close(handle)
    Linux => @linux.request_close(handle)
  }
}

///|
fn native_exit(backend : NativeBackend, code : Int) -> Unit {
  match backend {
    Windows => @windows.exit(code)
    Linux => @linux.exit(code)
  }
}

///|
fn native_set_control_flow(backend : NativeBackend, poll : Bool) -> Unit {
  match backend {
    Windows => @windows.set_control_flow(poll)
    Linux => @linux.set_control_flow(poll)
  }
}

///|
fn native_monitor_count(backend : NativeBackend) -> Int {
  match backend {
    Windows => @windows.monitor_count()
    Linux => @linux.monitor_count()
  }
}

///|
fn native_monitor_metric(
  backend : NativeBackend,
  index : Int,
  metric : Int,
) -> Int {
  match backend {
    Windows => @windows.monitor_metric(index, metric)
    Linux => @linux.monitor_metric(index, metric)
  }
}

///|
fn native_monitor_scale(backend : NativeBackend, index : Int) -> Double {
  match backend {
    Windows => @windows.monitor_scale(index)
    Linux => @linux.monitor_scale(index)
  }
}

///|
fn native_primary_monitor_index(backend : NativeBackend) -> Int {
  match backend {
    Windows => @windows.primary_monitor_index()
    Linux => @linux.primary_monitor_index()
  }
}

///|
fn native_current_monitor_index(
  backend : NativeBackend,
  handle : UInt64,
) -> Int {
  match backend {
    Windows => @windows.current_monitor_index(handle)
    Linux => @linux.current_monitor_index(handle)
  }
}

///|
fn native_set_event_callback(
  backend : NativeBackend,
  callback : (Int, Int, Int, Int, Double, Double) -> Unit,
) -> Unit {
  match backend {
    Windows => @windows.set_event_callback(callback)
    Linux => @linux.set_event_callback(callback)
  }
}

///|
fn native_open_proxy(backend : NativeBackend) -> UInt64 {
  match backend {
    Windows => @windows.open_proxy()
    Linux => @linux.open_proxy()
  }
}

///|
fn native_post_proxy_message(
  backend : NativeBackend,
  generation : UInt64,
  message : Bytes,
) -> Int {
  match backend {
    Windows => @windows.post_proxy_message(generation, message)
    Linux => @linux.post_proxy_message(generation, message)
  }
}

///|
fn native_proxy_is_open(backend : NativeBackend, generation : UInt64) -> Bool {
  match backend {
    Windows => @windows.proxy_is_open(generation)
    Linux => @linux.proxy_is_open(generation)
  }
}

///|
fn native_take_proxy_message(
  backend : NativeBackend,
  length : Ref[Int],
) -> Bytes {
  match backend {
    Windows => @windows.take_proxy_message(length)
    Linux => @linux.take_proxy_message(length)
  }
}

///|
fn native_run(backend : NativeBackend) -> Int {
  match backend {
    Windows => @windows.run()
    Linux => @linux.run()
  }
}
