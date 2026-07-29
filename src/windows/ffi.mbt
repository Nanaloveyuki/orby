///|
extern "C" fn native_init() -> Int = "orby_win_init"

///|
#borrow(title)
extern "C" fn native_create_window(
  title : Bytes,
  width : Int,
  height : Int,
  visible : Bool,
  resizable : Bool,
  id : Int,
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
extern "C" fn native_set_fullscreen_on(hwnd : UInt64, monitor : Int) -> Bool = "orby_win_set_fullscreen_on"

///|
extern "C" fn native_is_fullscreen(hwnd : UInt64) -> Bool = "orby_win_is_fullscreen"

///|
extern "C" fn native_set_min_inner_size(
  hwnd : UInt64,
  width : Int,
  height : Int,
) -> Unit = "orby_win_set_min_inner_size"

///|
extern "C" fn native_set_max_inner_size(
  hwnd : UInt64,
  width : Int,
  height : Int,
) -> Unit = "orby_win_set_max_inner_size"

///|
extern "C" fn native_set_inner_size(
  hwnd : UInt64,
  width : Int,
  height : Int,
) -> Unit = "orby_win_set_inner_size"

///|
extern "C" fn native_inner_width(hwnd : UInt64) -> Int = "orby_win_inner_width"

///|
extern "C" fn native_inner_height(hwnd : UInt64) -> Int = "orby_win_inner_height"

///|
extern "C" fn native_scale_factor(hwnd : UInt64) -> Double = "orby_win_scale_factor"

///|
extern "C" fn native_set_outer_position(
  hwnd : UInt64,
  x : Int,
  y : Int,
) -> Unit = "orby_win_set_outer_position"

///|
extern "C" fn native_request_close(hwnd : UInt64) -> Unit = "orby_win_request_close"

///|
extern "C" fn native_exit(code : Int) -> Unit = "orby_win_exit"

///|
extern "C" fn native_set_control_flow(poll : Bool) -> Unit = "orby_win_set_control_flow"

///|
extern "C" fn native_monitor_count() -> Int = "orby_win_monitor_count"

///|
extern "C" fn native_monitor_metric(index : Int, metric : Int) -> Int = "orby_win_monitor_metric"

///|
extern "C" fn native_monitor_scale(index : Int) -> Double = "orby_win_monitor_scale"

///|
extern "C" fn native_primary_monitor_index() -> Int = "orby_win_primary_monitor_index"

///|
extern "C" fn native_current_monitor_index(hwnd : UInt64) -> Int = "orby_win_current_monitor_index"

///|
#borrow(call_closure)
#owned(callback)
extern "C" fn native_set_event_callback(
  call_closure : FuncRef[
    (
      (Int, Int, Int, Int, Double, Double) -> Unit,
      Int,
      Int,
      Int,
      Int,
      Double,
      Double,
    ) -> Unit,
  ],
  callback : (Int, Int, Int, Int, Double, Double) -> Unit,
) -> Unit = "orby_win_set_event_callback"

///|
extern "C" fn native_open_proxy() -> UInt64 = "orby_win_proxy_open"

///|
#borrow(message)
extern "C" fn native_post_proxy_message(
  generation : UInt64,
  message : Bytes,
) -> Int = "orby_win_proxy_post"

///|
extern "C" fn native_proxy_is_open(generation : UInt64) -> Bool = "orby_win_proxy_is_open"

///|
#borrow(length)
extern "C" fn native_take_proxy_message(length : Ref[Int]) -> Bytes = "orby_win_proxy_take"

///|
extern "C" fn native_run() -> Int = "orby_win_run"
