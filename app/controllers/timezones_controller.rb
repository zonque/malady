class TimezonesController < ApplicationController
  def update
    if Time.find_zone(params[:time_zone].to_s)
      current_user.update(time_zone: params[:time_zone])
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
