# Be sure to restart your server when you modify this file.
#
# Content Security Policy. All of Malady's assets are served same-origin
# (JS via importmap, the Bootstrap Icons webfont, the SVG favicon), so the policy
# is a tight `:self` with a per-request nonce for the few inline <script> tags we
# emit (the importmap JSON and Chartkick's chart initializers — both pick the
# nonce up automatically).
#
# Inline STYLE is still allowed (`:unsafe_inline`): Chartkick/Chart.js and a few
# templates set `style="…"` attributes. Scripts do NOT get `:unsafe_inline`, so
# nonce-based script-src is real protection.
#
# Currently REPORT-ONLY: violations are reported by the browser but nothing is
# blocked. Once the violation reports are clean, flip `report_only` to false (or
# delete the line) to start enforcing.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.font_src    :self
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # Per-request nonce so inline <script> (importmap, Chartkick) can run under a
  # strict script-src without `:unsafe_inline`.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Warn-only for now — report violations without enforcing them.
  config.content_security_policy_report_only = true
end
