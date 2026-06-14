require "test_helper"

# Guards the vendored Bootstrap Icons assets and the generated ICON_NAMES module
# the picker depends on. If regeneration breaks, this fails loudly.
class BootstrapIconsTest < ActiveSupport::TestCase
  ICON_NAME_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  test "vendored webfont assets exist" do
    %w[
      public/bootstrap-icons/bootstrap-icons.css
      public/bootstrap-icons/fonts/bootstrap-icons.woff2
    ].each do |path|
      assert File.exist?(Rails.root.join(path)), "missing vendored asset: #{path}"
    end
  end

  test "ICON_NAMES module lists kebab-case icon names" do
    js = File.read(Rails.root.join("app/javascript/bootstrap_icons.js"))
    json = js[/ICON_NAMES\s*=\s*(\[.*\])/m, 1]
    assert json, "could not find ICON_NAMES array in bootstrap_icons.js"

    names = JSON.parse(json)
    assert_operator names.size, :>, 1500, "expected the full icon set"
    assert_includes names, "heart-fill"
    # Every name must satisfy the same format the Metric#icon validation enforces.
    bad = names.reject { |n| n.match?(ICON_NAME_FORMAT) }
    assert_empty bad, "non-kebab-case icon names: #{bad.first(5).inspect}"
  end
end
