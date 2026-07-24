# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      # POST /api/v1/users/signup
      def signup
        user = User.new(user_params)

        if user.save
          token = JsonWebToken.encode({ user_id: user.id })
          render_json(user_response(user, token), status: :created)
        else
          render_json({ errors: user.errors.full_messages }, status: :unprocessable_entity)
        end
      end

      private

      def user_params
        params.permit(:first_name, :last_name, :email, :password, :country)
      end

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
