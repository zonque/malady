class ApiTokensController < ApplicationController
  def show; end

  def update
    current_user.rotate_api_token!
    redirect_to api_token_path, notice: t(".regenerated")
  end
end
