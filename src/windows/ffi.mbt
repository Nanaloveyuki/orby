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
extern "C" fn native_exit() -> Unit = "orby_win_exit"

///|
#borrow(call_closure)
#owned(callback)
extern "C" fn native_set_event_callback(
  call_closure : FuncRef[
    ((Int, Int, Int, Int, Double) -> Unit, Int, Int, Int, Int, Double) -> Unit,
  ],
  callback : (Int, Int, Int, Int, Double) -> Unit,
) -> Unit = "orby_win_set_event_callback"

///|
extern "C" fn native_run() -> Int = "orby_win_run"
