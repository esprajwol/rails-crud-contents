# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      # POST /api/v1/auth/signin
      # Request body: { "auth": { "email": "...", "password": "..." } }
      def signin
        auth_params = params.require(:auth).permit(:email, :password)
        user = User.find_by(email: auth_params[:email]&.downcase)

        if user&.authenticate(auth_params[:password])
          token = JsonWebToken.encode({ user_id: user.id })
          render_json(user_response(user, token))
        else
          render_json({ error: "Invalid email or password" }, status: :unauthorized)
        end
      end

      private

      # Builds the JSON:API-flavoured envelope for a user resource.
      def user_response(user, token)
        {
          data: {
            id: user.id,
            type: "users",
            attributes: {
              token: token,
              email: user.email,
              name: user.name,
              country: user.country,
              created_at: user.created_at,
              updated_at: user.updated_at
            }
          }
        }
      end
    end
  end
end
