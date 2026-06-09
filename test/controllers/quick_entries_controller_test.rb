require "test_helper"

class QuickEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "q@m.test")
    @weight = @user.metrics.create!(name: "Weight", data_type: "decimal", unit: "kg")
    @mood = @user.metrics.create!(name: "Mood", data_type: "enumeration", enum_options: [ "low", "high" ])
    sign_in @user
  end

  test "new renders an input for each metric" do
    get new_quick_entry_path
    assert_response :success
    assert_select "input[name=?]", "values[#{@weight.id}]"
    assert_select "select[name=?]", "values[#{@mood.id}]"
  end

  test "create stores only filled metrics with the shared timestamp" do
    assert_difference -> { DataPoint.count }, 1 do
      post quick_entry_path, params: { recorded_at: "2026-03-01T08:00",
        values: { @weight.id.to_s => "73.2", @mood.id.to_s => "" } }
    end
    assert_redirected_to root_path
    assert_equal "73.2", @weight.data_points.last.value_text
    assert_equal 0, @mood.data_points.count
  end

  test "an invalid filled value saves nothing and re-renders 422" do
    assert_no_difference -> { DataPoint.count } do
      post quick_entry_path, params: { recorded_at: "2026-03-01T08:00",
        values: { @weight.id.to_s => "not-a-number", @mood.id.to_s => "low" } }
    end
    assert_response :unprocessable_entity
  end

  test "submitting nothing re-renders 422 without saving" do
    assert_no_difference -> { DataPoint.count } do
      post quick_entry_path, params: { recorded_at: "2026-03-01T08:00",
        values: { @weight.id.to_s => "", @mood.id.to_s => "" } }
    end
    assert_response :unprocessable_entity
  end

  test "requires auth" do
    sign_out @user
    get new_quick_entry_path
    assert_redirected_to new_user_session_path
  end

  test "cannot log to another user's metric (ignored)" do
    other = confirmed_user(email: "other@m.test")
    foreign = other.metrics.create!(name: "Secret", data_type: "decimal")
    assert_no_difference -> { DataPoint.count } do
      post quick_entry_path, params: { recorded_at: "2026-03-01T08:00",
        values: { foreign.id.to_s => "5" } }
    end
    assert_response :unprocessable_entity
    assert_equal 0, foreign.data_points.count
  end
end
