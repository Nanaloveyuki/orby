///|
fn normalize_dimension_for_test(value : Int) -> Int {
  if value < 1 {
    1
  } else {
    value
  }
}

///|
fn positive_scale_for_test(seed : Int) -> Double {
  ((seed & 15) + 1).to_double() / 4.0
}

///|
fn adversarial_double_for_test(tag : Int, value : Int) -> Double {
  match tag & 3 {
    0 => value.to_double()
    1 => (0.0 : Double) / 0.0
    2 => (1.0 : Double) / 0.0
    _ => (-1.0 : Double) / 0.0
  }
}

///|
fn positive_finite_for_test(value : Double) -> Bool {
  value > 0.0 && !Double::is_nan(value) && !Double::is_inf(value)
}

///|
test "quickcheck: sizes normalize arbitrary dimensions" {
  @quickcheck.check(
    (input : (Int, Int)) => {
      let (width, height) = input
      let size = Size::new(width~, height~)
      size.width >= 1 &&
      size.height >= 1 &&
      size.width == normalize_dimension_for_test(width) &&
      size.height == normalize_dimension_for_test(height) &&
      Size::new(width=size.width, height=size.height) == size
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082501,
  )
}

///|
test "quickcheck: logical sizes normalize finite and non-finite values" {
  @quickcheck.check(
    (input : (Int, Int, Int, Int)) => {
      let (width_tag, width_seed, height_tag, height_seed) = input
      let width = adversarial_double_for_test(width_tag, width_seed)
      let height = adversarial_double_for_test(height_tag, height_seed)
      let logical = LogicalSize::new(width~, height~)
      let expected_width = if positive_finite_for_test(width) {
        width
      } else {
        1.0
      }
      let expected_height = if positive_finite_for_test(height) {
        height
      } else {
        1.0
      }
      logical.width == expected_width &&
      logical.height == expected_height &&
      logical.width > 0.0 &&
      logical.height > 0.0 &&
      !Double::is_nan(logical.width) &&
      !Double::is_nan(logical.height) &&
      !Double::is_inf(logical.width) &&
      !Double::is_inf(logical.height) &&
      LogicalSize::new(width=logical.width, height=logical.height) == logical
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082502,
  )
}

///|
test "quickcheck: scale-factor validation covers adversarial values" {
  @quickcheck.check(
    (input : (Int, Int)) => {
      let (tag, value) = input
      let scale_factor = adversarial_double_for_test(tag, value)
      validate_scale_factor(scale_factor) ==
      positive_finite_for_test(scale_factor)
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082503,
  )
}

///|
test "quickcheck: unit-scale geometry is reversible" {
  @quickcheck.check(
    (input : (Int, Int)) => {
      let (width, height) = input
      let size = Size::new(width~, height~)
      let logical = size.to_logical(1.0)
      logical.width == size.width.to_double() &&
      logical.height == size.height.to_double() &&
      logical.to_physical(1.0) == size
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082504,
  )
}

///|
/// Correlated dimensions exercise monotonicity without depending on one
/// particular rounded pixel result.
test "quickcheck: physical geometry is monotone" {
  @quickcheck.check(
    (input : (Int, Int, Int, Int, Int)) => {
      let (base_width, width_delta, base_height, height_delta, scale_seed) = input
      let low_width = ((base_width & 1023) + 1).to_double()
      let low_height = ((base_height & 1023) + 1).to_double()
      let high_width = low_width + (width_delta & 1023).to_double()
      let high_height = low_height + (height_delta & 1023).to_double()
      let scale_factor = positive_scale_for_test(scale_seed)
      let low = LogicalSize::new(width=low_width, height=low_height)
      let high = LogicalSize::new(width=high_width, height=high_height)
      let low_physical = low.to_physical(scale_factor)
      let high_physical = high.to_physical(scale_factor)
      low_physical.width <= high_physical.width &&
      low_physical.height <= high_physical.height
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082505,
  )
}

///|
test "quickcheck: monitor IDs accept exactly non-negative indexes" {
  @quickcheck.check(
    (index : Int) => {
      match MonitorId::from_index(index) {
        None => index < 0
        Some(id) => index >= 0 && id.index() == index
      }
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082510,
  )
}

///|
test "quickcheck: monitors preserve identity and normalize bounds" {
  @quickcheck.check(
    (input : (Int, Int, Int, Int, Int, Int, Int, Int)) => {
      let (id_seed, x, y, width, height, work_width, work_height, scale_seed) = input
      match MonitorId::from_index(id_seed & 1023) {
        None => false
        Some(id) => {
          let scale_factor = adversarial_double_for_test(scale_seed, scale_seed)
          let monitor = Monitor::new(
            id~,
            x~,
            y~,
            width~,
            height~,
            work_x=x,
            work_y=y,
            work_width~,
            work_height~,
            scale_factor~,
          )
          monitor.id == id &&
          monitor.x == x &&
          monitor.y == y &&
          monitor.width == normalize_dimension_for_test(width) &&
          monitor.height == normalize_dimension_for_test(height) &&
          monitor.work_x == x &&
          monitor.work_y == y &&
          monitor.work_width == normalize_dimension_for_test(work_width) &&
          monitor.work_height == normalize_dimension_for_test(work_height) &&
          monitor.scale_factor ==
          (if validate_scale_factor(scale_factor) { scale_factor } else { 1.0 })
        }
      }
    },
    count=250,
    max_size=512,
    max_shrinks=200,
    seed=2026082506,
  )
}

///|
test "non-finite scale factors are rejected" {
  let nan = (0.0 : Double) / 0.0
  let infinity = (1.0 : Double) / 0.0
  let neg_infinity = (-1.0 : Double) / 0.0
  assert_false(validate_scale_factor(nan))
  assert_false(validate_scale_factor(infinity))
  assert_false(validate_scale_factor(neg_infinity))
}
