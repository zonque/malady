require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  def metric(type, enum_options: [])
    Metric.new(data_type: type, enum_options: enum_options)
  end

  test "metric_chartable? only for numeric and boolean" do
    %w[decimal integer percentage boolean].each { |t| assert metric_chartable?(Metric.new(data_type: t)) }
    %w[enumeration text text_block].each { |t| assert_not metric_chartable?(Metric.new(data_type: t)) }
  end

  test "metric_chart_data builds time/value pairs for numeric metrics" do
    user = User.create!(email: "c@h.t", password: "password123")
    m = user.metrics.create!(name: "W", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 2, 8), value: "72")
    data = metric_chart_data(m)
    assert_equal 2, data.size
    assert_equal 70, data.first.last
  end

  test "metric_chart_data maps boolean to 1/0 and is nil for text" do
    user = User.create!(email: "c2@h.t", password: "password123")
    b = user.metrics.create!(name: "B", data_type: "boolean")
    b.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "yes")
    b.data_points.create!(recorded_at: Time.utc(2026, 1, 2), value: "no")
    assert_equal [ 1, 0 ], metric_chart_data(b).map(&:last)
    t = user.metrics.create!(name: "T", data_type: "text")
    assert_nil metric_chart_data(t)
  end

  test "enumeration renders a select with its options" do
    html = metric_value_input(metric("enumeration", enum_options: [ "low", "high" ]), name: "data_point[value]")
    assert_match %r{<select[^>]*name="data_point\[value\]"}, html
    assert_match ">low</option>", html
    assert_match ">high</option>", html
  end

  test "boolean renders a yes/no select" do
    html = metric_value_input(metric("boolean"), name: "data_point[value]")
    assert_match "<select", html
    assert_match ">Yes</option>", html
    assert_match ">No</option>", html
  end

  test "integer and decimal render number inputs" do
    assert_match %r{<input[^>]*type="number"}, metric_value_input(metric("integer"), name: "x")
    assert_match %r{<input[^>]*type="number"}, metric_value_input(metric("decimal"), name: "x")
  end

  test "text renders a text input" do
    assert_match %r{<input[^>]*type="text"}, metric_value_input(metric("text"), name: "x")
  end

  test "text_block renders a resizable textarea prefilled with the value" do
    html = metric_value_input(metric("text_block"), name: "x", value: "line one\nline two")
    assert_match %r{<textarea}, html
    assert_match "resize", html
    assert_match "line one\nline two", html
  end

  test "prefills the current value" do
    html = metric_value_input(metric("text"), name: "x", value: "hello")
    assert_match 'value="hello"', html
  end

  test "memory_label reads in months under a year and years at year boundaries" do
    assert_equal "1 month ago", memory_label(1)
    assert_equal "3 months ago", memory_label(3)
    assert_equal "1 year ago", memory_label(12)
    assert_equal "2 years ago", memory_label(24)
    assert_equal "4 years ago", memory_label(48)
  end

  test "render_markdown converts markdown and strips raw html" do
    html = render_markdown("# Heading\n\n**bold** and *italic*\n\n<script>alert(1)</script>")
    assert_match %r{<h1[^>]*>Heading</h1>}, html
    assert_match "<strong>bold</strong>", html
    # The <script> tag is stripped; any residual text is harmless and not executable.
    assert_not_includes html, "<script"
  end

  test "metric_value_display renders markdown for text_block and plain text otherwise" do
    user = User.create!(email: "md@h.t", password: "password123")

    tb = user.metrics.create!(name: "Journal", data_type: "text_block")
    tb_dp = tb.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "**hi**")
    assert_match "<strong>hi</strong>", metric_value_display(tb, tb_dp)

    txt = user.metrics.create!(name: "Note", data_type: "text")
    txt_dp = txt.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "**hi**")
    display = metric_value_display(txt, txt_dp)
    assert_not_includes display, "<strong>"
    assert_match "**hi**", display
  end
end
