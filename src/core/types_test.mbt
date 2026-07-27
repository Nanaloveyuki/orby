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
test "physical positions preserve negative desktop coordinates" {
  debug_inspect(Position::new(x=-120, y=48), content="{ x: -120, y: 48 }")
}

///|
test "monitor normalizes unusable native metrics" {
  let id = match MonitorId::from_index(0) {
    Some(id) => id
    None => fail("zero is a valid monitor index")
  }
  let monitor = Monitor::new(
    id~,
    x=-12,
    y=8,
    width=0,
    height=-1,
    work_x=-12,
    work_y=8,
    work_width=0,
    work_height=-1,
    scale_factor=0.0,
  )
  debug_inspect(
    monitor,
    content="{\n  id: { index_: 0 },\n  x: -12,\n  y: 8,\n  width: 1,\n  height: 1,\n  work_x: -12,\n  work_y: 8,\n  work_width: 1,\n  work_height: 1,\n  scale_factor: 1,\n}",
  )
}

///|
test "monitor IDs reject negative native indexes" {
  debug_inspect(MonitorId::from_index(-1), content="None")
}
