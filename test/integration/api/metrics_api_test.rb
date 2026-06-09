require "test_helper"

class MetricsApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "a@b.c", password: "password123")
    @metric = @user.metrics.create!(name: "Weight", slug: "weight", data_type: "decimal", unit: "kg")
  end

  def auth = { "Authorization" => "Bearer #{@user.api_token}" }

  test "rejects missing token" do
    get api_v1_metrics_path
    assert_response :unauthorized
  end

  test "lists the owner's metrics" do
    other = User.create!(email: "x@y.z", password: "password123")
    other.metrics.create!(name: "Secret", slug: "secret", data_type: "text")
    get api_v1_metrics_path, headers: auth
    assert_response :success
    body = JSON.parse(response.body)
    slugs = body.map { |m| m["slug"] }
    assert_includes slugs, "weight"
    assert_not_includes slugs, "secret"
  end

  test "series returns time/value pairs filtered by range" do
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "70")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 2, 1), value: "72")
    get series_api_v1_metric_path(@metric.slug, from: "2026-01-15T00:00:00Z"), headers: auth
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal 72.0, body.first["value"]
    assert_equal "2026-02-01T00:00:00Z", body.first["time"]
  end

  test "series is owner-scoped" do
    other = User.create!(email: "x@y.z", password: "password123")
    theirs = other.metrics.create!(name: "Secret", slug: "secret", data_type: "decimal")
    get series_api_v1_metric_path(theirs.slug), headers: auth
    assert_response :not_found
  end
end
