///|
pub fn initialize() -> Bool {
  native_init() != 0
}

///|
pub fn create_window(
  title : Bytes,
  width : Int,
  height : Int,
  visible : Bool,
  resizable : Bool,
  id : Int,
) -> UInt64 {
  native_create_window(title, width, height, visible, resizable, id)
}

///|
pub fn destroy_window(handle : UInt64) -> Unit {
  native_destroy_window(handle)
}

///|
pub fn set_title(handle : UInt64, title : Bytes) -> Unit {
  native_set_title(handle, title)
}

///|
pub fn request_redraw(handle : UInt64) -> Unit {
  native_request_redraw(handle)
}

///|
pub fn set_visible(handle : UInt64, visible : Bool) -> Unit {
  native_set_visible(handle, visible)
}

///|
pub fn set_resizable(handle : UInt64, resizable : Bool) -> Unit {
  native_set_resizable(handle, resizable)
}

///|
pub fn set_minimized(handle : UInt64, minimized : Bool) -> Unit {
  native_set_minimized(handle, minimized)
}

///|
pub fn is_minimized(handle : UInt64) -> Bool {
  native_is_minimized(handle)
}

///|
pub fn set_maximized(handle : UInt64, maximized : Bool) -> Unit {
  native_set_maximized(handle, maximized)
}

///|
pub fn is_maximized(handle : UInt64) -> Bool {
  native_is_maximized(handle)
}

///|
pub fn set_decorated(handle : UInt64, decorated : Bool) -> Unit {
  native_set_decorated(handle, decorated)
}

///|
pub fn set_fullscreen(handle : UInt64, fullscreen : Bool) -> Unit {
  native_set_fullscreen(handle, fullscreen)
}

///|
pub fn set_fullscreen_on(handle : UInt64, monitor : Int) -> Bool {
  native_set_fullscreen_on(handle, monitor)
}

///|
pub fn is_fullscreen(handle : UInt64) -> Bool {
  native_is_fullscreen(handle)
}

///|
pub fn set_min_inner_size(handle : UInt64, width : Int, height : Int) -> Unit {
  native_set_min_inner_size(handle, width, height)
}

///|
pub fn set_max_inner_size(handle : UInt64, width : Int, height : Int) -> Unit {
  native_set_max_inner_size(handle, width, height)
}

///|
pub fn set_inner_size(handle : UInt64, width : Int, height : Int) -> Unit {
  native_set_inner_size(handle, width, height)
}

///|
pub fn inner_width(handle : UInt64) -> Int {
  native_inner_width(handle)
}

///|
pub fn inner_height(handle : UInt64) -> Int {
  native_inner_height(handle)
}

///|
pub fn scale_factor(handle : UInt64) -> Double {
  native_scale_factor(handle)
}

///|
pub fn set_outer_position(handle : UInt64, x : Int, y : Int) -> Unit {
  native_set_outer_position(handle, x, y)
}

///|
pub fn request_close(handle : UInt64) -> Unit {
  native_request_close(handle)
}

///|
pub fn exit(code : Int) -> Unit {
  native_exit(code)
}

///|
pub fn set_control_flow(poll : Bool) -> Unit {
  native_set_control_flow(poll)
}

///|
pub fn monitor_count() -> Int {
  native_monitor_count()
}

///|
pub fn monitor_metric(index : Int, metric : Int) -> Int {
  native_monitor_metric(index, metric)
}

///|
pub fn monitor_scale(index : Int) -> Double {
  native_monitor_scale(index)
}

///|
pub fn primary_monitor_index() -> Int {
  native_primary_monitor_index()
}

///|
pub fn current_monitor_index(handle : UInt64) -> Int {
  native_current_monitor_index(handle)
}

///|
pub fn set_event_callback(
  callback : (Int, Int, Int, Int, Double, Double) -> Unit,
) -> Unit {
  native_set_event_callback(
    fn(callback, kind, id, arg0, arg1, argd0, argd1) {
      callback(kind, id, arg0, arg1, argd0, argd1)
    },
    callback,
  )
}

///|
pub fn run() -> Int {
  native_run()
}
