class ApplicationController < ActionController::Base
  # NOTE: the scaffolded `allow_browser versions: :modern` was removed — its
  # user-agent heuristic returns 406 for legitimate browsers (e.g. Firefox in
  # mobile/responsive mode), locking real users out. Malady's CSS/JS work in all
  # current browsers, so we don't gate by UA.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
end
