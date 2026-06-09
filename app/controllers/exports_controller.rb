class ExportsController < ApplicationController
  def json
    render json: Exporters::Json.new(current_user).to_json
  end

  def csv
    send_data Exporters::Csv.new(current_user).to_csv,
              filename: "malady-#{Date.current.iso8601}.csv",
              type: "text/csv"
  end
end
