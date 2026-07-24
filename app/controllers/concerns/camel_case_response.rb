# frozen_string_literal: true

# Provides a helper to transform response hashes to camelCase keys
# before rendering. Include this in ApplicationController and call
# `render_json` instead of `render json:` in every controller action.
module CamelCaseResponse
  extend ActiveSupport::Concern

  # Renders a JSON response with all keys transformed to camelCase.
  #
  # @param data [Hash] the response data
  # @param status [Integer, Symbol] HTTP status (default: :ok)
  def render_json(data, status: :ok)
    render json: deep_transform_keys_to_camel_case(data), status: status
  end

  private

  # Recursively converts all keys in the given object to camelCase.
  def deep_transform_keys_to_camel_case(value)
    case value
    when Hash
      value.transform_keys { |k| k.to_s.camelize(:lower) }.transform_values do |v|
        deep_transform_keys_to_camel_case(v)
      end
    when Array
      value.map { |v| deep_transform_keys_to_camel_case(v) }
    else
      value
    end
  end
end
