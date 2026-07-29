///|
test "proxy status maps to explicit errors" {
  assert_eq(proxy_post_result(0), Err(Closed))
  assert_eq(proxy_post_result(2), Err(MessageTooLarge))
  assert_eq(proxy_post_result(3), Err(QueueFull))
}
