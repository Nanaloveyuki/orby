///|
test "size is never empty" {
  debug_inspect(
    Size::new(width=0, height=-5),
    content="{ width: 1, height: 1 }",
  )
}

///|
test "window options have a usable default" {
  let options = WindowOptions::new()
  debug_inspect(options.size, content="{ width: 800, height: 600 }")
}
