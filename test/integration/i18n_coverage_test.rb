require "test_helper"

class I18nCoverageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "i18n@m.test", admin: true)
    @metric = @user.metrics.create!(name: "Weight", data_type: "decimal", unit: "kg")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
  end

  test "no missing translations on the main pages" do
    sign_in @user
    paths = [ root_path, metrics_path, new_metric_path, metric_path(@metric),
             edit_metric_path(@metric), edit_metric_metric_type_path(@metric),
             new_quick_entry_path, api_token_path, admin_users_path ]
    paths.each do |path|
      get path
      assert_response :success, "GET #{path} failed"
      assert_no_match(/translation missing|translation_missing/i, response.body, "missing translation on #{path}")
    end
  end

  test "no missing translations on the sign-in page" do
    get new_user_session_path
    assert_response :success
    assert_no_match(/translation missing/i, response.body)
  end
end
