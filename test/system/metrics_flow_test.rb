require "application_system_test_case"

class MetricsFlowTest < ApplicationSystemTestCase
  # The browser is a separate process that gets its own DB connection; it cannot
  # see records that only exist inside an uncommitted transaction.  Turning off
  # transactional tests causes every write to be committed so the browser finds
  # the user.  We clean up in teardown instead.
  self.use_transactional_tests = false

  setup do
    # Purge any leftover rows from a previous aborted run (use_transactional_tests
    # is off, so there is no automatic rollback).
    DataPoint.delete_all
    Metric.delete_all
    User.delete_all
    @user = confirmed_user(email: "a@b.c")
  end

  teardown do
    DataPoint.delete_all
    Metric.delete_all
    User.delete_all
  end

  test "create a metric and log a data point" do
    visit new_user_session_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Log in"
    # After successful login Devise redirects to the root; wait for it.
    assert_no_text "You need to sign in"

    visit new_metric_path
    fill_in "Name", with: "Weight"
    select "Decimal", from: "Data type"
    # Chrome 149 headless: clicking input[type=submit] doesn't trigger Turbo's
    # submit handler; native form.submit() bypasses the issue entirely.
    execute_script("document.querySelector('form').submit()")

    assert_text "Metric created."
    assert_text "Weight"
    execute_script(<<~JS)
      document.getElementById('data_point_value').value = '72.5';
      document.querySelector('form[action*="data_points"]').submit();
    JS
    assert_text "72.5"
  end
end
