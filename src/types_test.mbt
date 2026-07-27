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

///|
test "logical size converts through a scale factor" {
  let logical = LogicalSize::new(width=320.0, height=240.0)
  debug_inspect(
    logical.to_physical(1.25),
    content="{ width: 400, height: 300 }",
  )
  debug_inspect(
    Size::new(width=400, height=300).to_logical(1.25),
    content="{ width: 320, height: 240 }",
  )
}

///|
test "scale conversion rejects invalid factors" {
  try LogicalSize::new(width=320.0, height=240.0).to_physical(0.0) catch {
    GeometryError::InvalidScaleFactor(scale_factor) =>
      assert_true(scale_factor == 0.0)
  } noraise {
    _ => fail("expected an invalid scale-factor error")
  }
  try Size::new(width=400, height=300).to_logical(-1.0) catch {
    GeometryError::InvalidScaleFactor(scale_factor) =>
      assert_true(scale_factor == -1.0)
  } noraise {
    _ => fail("expected an invalid scale-factor error")
  }
}

///|
test "monitor IDs reject negative native indexes" {
  debug_inspect(MonitorId::from_index(-1), content="None")
}
