///|
extern "C" fn native_init() -> Int32 = "orby_win_init"

///|
extern "C" fn native_is_active() -> Bool = "orby_win_is_active"

///|
#borrow(title)
extern "C" fn native_create_window(
  title : Bytes,
  width : Int32,
  height : Int32,
  visible : Bool,
  resizable : Bool,
  id : Int32,
) -> UInt64 = "orby_win_create_window"

///|
extern "C" fn native_destroy_window(hwnd : UInt64) -> Unit = "orby_win_destroy_window"

///|
#borrow(title)
extern "C" fn native_set_title(hwnd : UInt64, title : Bytes) -> Unit = "orby_win_set_title"

///|
extern "C" fn native_request_redraw(hwnd : UInt64) -> Unit = "orby_win_request_redraw"

///|
extern "C" fn native_set_visible(hwnd : UInt64, visible : Bool) -> Unit = "orby_win_set_visible"

///|
extern "C" fn native_focus_window(hwnd : UInt64) -> Unit = "orby_win_focus_window"

///|
extern "C" fn native_set_resizable(hwnd : UInt64, resizable : Bool) -> Unit = "orby_win_set_resizable"

///|
extern "C" fn native_set_minimized(hwnd : UInt64, minimized : Bool) -> Unit = "orby_win_set_minimized"

///|
extern "C" fn native_is_minimized(hwnd : UInt64) -> Bool = "orby_win_is_minimized"

///|
extern "C" fn native_set_maximized(hwnd : UInt64, maximized : Bool) -> Unit = "orby_win_set_maximized"

///|
extern "C" fn native_is_maximized(hwnd : UInt64) -> Bool = "orby_win_is_maximized"

///|
extern "C" fn native_set_decorated(hwnd : UInt64, decorated : Bool) -> Unit = "orby_win_set_decorated"

///|
extern "C" fn native_set_fullscreen(hwnd : UInt64, fullscreen : Bool) -> Unit = "orby_win_set_fullscreen"

///|
extern "C" fn native_set_fullscreen_on(hwnd : UInt64, monitor : Int32) -> Bool = "orby_win_set_fullscreen_on"

///|
extern "C" fn native_is_fullscreen(hwnd : UInt64) -> Bool = "orby_win_is_fullscreen"

///|
extern "C" fn native_set_min_inner_size(
  hwnd : UInt64,
  width : Int32,
  height : Int32,
) -> Unit = "orby_win_set_min_inner_size"

///|
extern "C" fn native_set_max_inner_size(
  hwnd : UInt64,
  width : Int32,
  height : Int32,
) -> Unit = "orby_win_set_max_inner_size"

///|
extern "C" fn native_set_inner_size(
  hwnd : UInt64,
  width : Int32,
  height : Int32,
) -> Unit = "orby_win_set_inner_size"

///|
extern "C" fn native_inner_width(hwnd : UInt64) -> Int32 = "orby_win_inner_width"

///|
extern "C" fn native_inner_height(hwnd : UInt64) -> Int32 = "orby_win_inner_height"

///|
extern "C" fn native_scale_factor(hwnd : UInt64) -> Double = "orby_win_scale_factor"

///|
extern "C" fn native_set_outer_position(
  hwnd : UInt64,
  x : Int32,
  y : Int32,
) -> Unit = "orby_win_set_outer_position"

///|
extern "C" fn native_request_close(hwnd : UInt64) -> Unit = "orby_win_request_close"

///|
extern "C" fn native_exit(code : Int32) -> Unit = "orby_win_exit"

///|
extern "C" fn native_set_control_flow(poll : Bool) -> Unit = "orby_win_set_control_flow"

///|
extern "C" fn native_monitor_count() -> Int32 = "orby_win_monitor_count"

///|
extern "C" fn native_monitor_metric(index : Int32, metric : Int32) -> Int32 = "orby_win_monitor_metric"

///|
extern "C" fn native_monitor_scale(index : Int32) -> Double = "orby_win_monitor_scale"

///|
extern "C" fn native_primary_monitor_index() -> Int32 = "orby_win_primary_monitor_index"

///|
extern "C" fn native_current_monitor_index(hwnd : UInt64) -> Int32 = "orby_win_current_monitor_index"

///|
#borrow(call_closure)
#owned(callback)
extern "C" fn native_set_event_callback(
  call_closure : FuncRef[
    (
      (Int32, Int32, Int32, Int32, Double, Double) -> Unit,
      Int32,
      Int32,
      Int32,
      Int32,
      Double,
      Double,
    ) -> Unit,
  ],
  callback : (Int32, Int32, Int32, Int32, Double, Double) -> Unit,
) -> Unit = "orby_win_set_event_callback"

///|
extern "C" fn native_open_proxy() -> UInt64 = "orby_win_proxy_open"

///|
#borrow(message)
extern "C" fn native_post_proxy_message(
  generation : UInt64,
  message : Bytes,
) -> Int32 = "orby_win_proxy_post"

///|
extern "C" fn native_proxy_is_open(generation : UInt64) -> Bool = "orby_win_proxy_is_open"

///|
#borrow(length)
extern "C" fn native_take_proxy_message(length : Ref[Int32]) -> Bytes = "orby_win_proxy_take"

///|
extern "C" fn native_run() -> Int32 = "orby_win_run"

///|
extern "C" fn native_poll(timeout : Int32) -> Int32 = "orby_win_poll"

///|
extern "C" fn native_finish() -> Int32 = "orby_win_finish"

///|
extern "C" fn native_wake_external_loop() -> Unit = "orby_win_wake_external_loop"
