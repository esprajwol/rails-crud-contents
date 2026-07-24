# frozen_string_literal: true

module Api
  module V1
    class ContentsController < ApplicationController
      include Authenticatable

      before_action :set_content, only: %i[show update destroy]
      before_action :authorize_owner!, only: %i[update destroy]

      # GET /api/v1/contents
      # GET /api/v1/content  (alias)
      def index
        contents = Content.all.order(created_at: :desc)
        render_json({ data: contents.map { |c| content_data(c) } })
      end

      # GET /api/v1/contents/:id
      def show
        render_json({ data: content_data(@content) })
      end

      # POST /api/v1/contents
      def create
        content = current_user.contents.build(content_params)

        if content.save
          render_json({ data: content_data(content) }, status: :created)
        else
          render_json({ errors: content.errors.full_messages }, status: :unprocessable_entity)
        end
      end

      # PUT /api/v1/contents/:id
      def update
        if @content.update(content_params)
          render_json({ data: content_data(@content) })
        else
          render_json({ errors: @content.errors.full_messages }, status: :unprocessable_entity)
        end
      end

      # DELETE /api/v1/contents/:id
      def destroy
        @content.destroy
        render_json({ message: "Deleted" })
      end

      private

      def set_content
        @content = Content.find(params[:id])
      end

      def content_params
        params.require(:content).permit(:title, :body)
      rescue ActionController::ParameterMissing
        # Allow params at the root level too (some clients may not nest under "content")
        params.permit(:title, :body)
      end

      def authorize_owner!
        unless @content.user_id == current_user.id
          render_json(
            { error: "You are not authorized to modify this content" },
            status: :forbidden
          )
        end
      end

      # Builds the JSON:API-flavoured data object for a content resource.
      # Does NOT expose user_id in attributes per spec.
      def content_data(content)
        {
          id: content.id,
          type: "content",
          attributes: {
            title: content.title,
            body: content.body,
            created_at: content.created_at,
            updated_at: content.updated_at
          }
        }
      end
    end
  end
end
