require "application_system_test_case"

class IconPickerTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  setup do
    DataPoint.delete_all
    Metric.delete_all
    User.delete_all
    @user = confirmed_user(email: "icons@b.c")
  end

  teardown do
    DataPoint.delete_all
    Metric.delete_all
    User.delete_all
  end

  def login
    visit new_user_session_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Log in"
    assert_no_text "You need to sign in"
  end

  test "searching and picking an icon sets it on the new metric" do
    login
    visit new_metric_path

    # The grid renders icons on connect (importmap module loaded the names).
    assert_selector "[data-icon-picker-target='grid'] button i.bi", minimum: 1

    fill_in "icon_search", with: "heart-pulse"
    icon_button = find("[data-icon-picker-target='grid'] button[data-name='heart-pulse']")
    icon_button.click

    # The hidden field now carries the chosen name.
    assert_equal "heart-pulse", find("input[name='metric[icon]']", visible: :all).value

    fill_in "Name", with: "Heart Rate"
    select "Integer", from: "Data type"
    execute_script("document.querySelector('form').submit()")

    assert_text "Metric created."
    assert_selector "h1.page-title i.bi.bi-heart-pulse"
    assert_equal "heart-pulse", Metric.find_by(name: "Heart Rate").icon
  end

  test "the full icon set is browsable without searching, via scroll loading" do
    login
    visit new_metric_path

    grid = find("[data-icon-picker-target='grid']")
    # The first batch is rendered (well beyond the old 120 cap) and the count
    # reports the full set is available.
    assert_operator grid.all("button[data-name]").size, :>=, 200
    assert_match %r{/ 2078\z}, find("[data-icon-picker-target='count']").text

    # Scrolling the grid loads more icons.
    before = grid.all("button[data-name]").size
    execute_script(<<~JS)
      const g = document.querySelector("[data-icon-picker-target='grid']");
      g.scrollTop = g.scrollHeight;
    JS
    assert_operator grid.all("button[data-name]").size, :>, before
  end
end
