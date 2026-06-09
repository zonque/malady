module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token!
      # Owner-scoped finders raise RecordNotFound for foreign/unknown slugs → 404.
      rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

      private

      def authenticate_token!
        # Case-insensitive "Bearer " prefix per RFC 7235.
        token = request.headers["Authorization"].to_s.sub(/\ABearer\s+/i, "").strip
        @current_user = User.find_by(api_token: token) if token.present?
        head :unauthorized unless @current_user
      end

      attr_reader :current_user
    end
  end
end
