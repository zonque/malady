class Metrics::PositionsController < ApplicationController
  def update
    Array(params[:order]).each_with_index do |id, index|
      current_user.metrics.where(id: id).update_all(position: index)
    end
    head :no_content
  end
end
