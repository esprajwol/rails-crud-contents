# frozen_string_literal: true

class ApplicationController < ActionController::API
  include CamelCaseParams
  include CamelCaseResponse

  # Central error handling
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_json({ error: e.message }, status: :not_found)
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_json({ error: e.message }, status: :bad_request)
  end

  rescue_from ActionDispatch::Http::Parameters::ParseError do |e|
    render_json({ error: "Invalid JSON format in request body" }, status: :bad_request)
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render_json({ errors: e.record.errors.full_messages }, status: :unprocessable_entity)
  end
end
