require "test_helper"

class ExceptionRecipientsTest < ActiveSupport::TestCase
  test "parses a comma-separated list, trimming blanks" do
    assert_equal ["a@x.com", "b@x.com"],
      Malady.exception_recipients("MALADY_EXCEPTION_RECIPIENTS" => " a@x.com , b@x.com , ")
  end

  test "empty when unset" do
    assert_equal [], Malady.exception_recipients({})
  end
end
