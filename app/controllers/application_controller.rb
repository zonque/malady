class ApplicationController < ActionController::Base
  # NOTE: the scaffolded `allow_browser versions: :modern` was removed — its
  # user-agent heuristic returns 406 for legitimate browsers (e.g. Firefox in
  # mobile/responsive mode), locking real users out. Malady's CSS/JS work in all
  # current browsers, so we don't gate by UA.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  around_action :use_user_time_zone

  private

  # Render and parse times in the signed-in user's zone. Timestamps are stored in
  # UTC (Active Record's time_zone_aware_attributes converts on read/write), but
  # datetime-local inputs are naive wall-clock: this makes the entry form default
  # to local time and interprets a submitted value as local before storing UTC.
  def use_user_time_zone(&block)
    Time.use_zone(current_user&.time_zone.presence || Rails.application.config.time_zone, &block)
  end
end
