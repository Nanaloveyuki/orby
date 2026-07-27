///|
extern "C" fn native_init() -> Int = "orby_gtk_init"

///|
#borrow(title)
extern "C" fn native_create_window(
  title : Bytes,
  width : Int,
  height : Int,
  visible : Bool,
  resizable : Bool,
  id : Int,
) -> UInt64 = "orby_gtk_create_window"

///|
extern "C" fn native_destroy_window(host : UInt64) -> Unit = "orby_gtk_destroy_window"

///|
#borrow(title)
extern "C" fn native_set_title(host : UInt64, title : Bytes) -> Unit = "orby_gtk_set_title"

///|
extern "C" fn native_request_redraw(host : UInt64) -> Unit = "orby_gtk_request_redraw"

///|
extern "C" fn native_set_visible(host : UInt64, visible : Bool) -> Unit = "orby_gtk_set_visible"

///|
extern "C" fn native_set_resizable(host : UInt64, resizable : Bool) -> Unit = "orby_gtk_set_resizable"

///|
extern "C" fn native_set_inner_size(
  host : UInt64,
  width : Int,
  height : Int,
) -> Unit = "orby_gtk_set_inner_size"

///|
extern "C" fn native_inner_width(host : UInt64) -> Int = "orby_gtk_inner_width"

///|
extern "C" fn native_inner_height(host : UInt64) -> Int = "orby_gtk_inner_height"

///|
extern "C" fn native_scale_factor(host : UInt64) -> Double = "orby_gtk_scale_factor"

///|
extern "C" fn native_set_outer_position(
  host : UInt64,
  x : Int,
  y : Int,
) -> Unit = "orby_gtk_set_outer_position"

///|
extern "C" fn native_request_close(host : UInt64) -> Unit = "orby_gtk_request_close"

///|
extern "C" fn native_exit(code : Int) -> Unit = "orby_gtk_exit"

///|
#borrow(call_closure)
#owned(callback)
extern "C" fn native_set_event_callback(
  call_closure : FuncRef[
    ((Int, Int, Int, Int, Double) -> Unit, Int, Int, Int, Int, Double) -> Unit,
  ],
  callback : (Int, Int, Int, Int, Double) -> Unit,
) -> Unit = "orby_gtk_set_event_callback"

///|
extern "C" fn native_run() -> Int = "orby_gtk_run"
