///|
test "quickcheck: proxy status mapping is total" {
  @quickcheck.check(
    (status : Int) => {
      match proxy_post_result(status) {
        Ok(_) => status == 1
        Err(MessageTooLarge) => status == 2
        Err(QueueFull) => status == 3
        Err(Closed) => status != 1 && status != 2 && status != 3
      }
    },
    count=250,
    max_size=2048,
    max_shrinks=200,
    seed=2026082507,
  )
}

///|
test "quickcheck: runtime failure keeps the first reason" {
  @quickcheck.check(
    (reasons : (String, String, String)) => {
      let (first, second, third) = reasons
      let failure : Ref[String?] = Ref(None)
      let first_recorded = record_runtime_failure(failure, first)
      let second_recorded = record_runtime_failure(failure, second)
      let third_recorded = record_runtime_failure(failure, third)
      first_recorded &&
      !second_recorded &&
      !third_recorded &&
      failure.val == Some(first)
    },
    count=200,
    max_size=64,
    max_shrinks=200,
    seed=2026082508,
  )
}
