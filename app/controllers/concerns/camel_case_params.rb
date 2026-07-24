# frozen_string_literal: true

# Transforms incoming request params keys from camelCase to snake_case
# recursively before any action runs. Include this in ApplicationController.
module CamelCaseParams
  extend ActiveSupport::Concern

  included do
    before_action :transform_params
  end

  private

  def transform_params
    transformed = deep_transform_keys_to_snake_case(params.to_unsafe_h)
    params.merge!(transformed)
  end

  # Recursively converts all keys in the given object to snake_case.
  def deep_transform_keys_to_snake_case(value)
    case value
    when Hash
      value.each_with_object({}) do |(k, v), result|
        result[k.to_s.underscore] = deep_transform_keys_to_snake_case(v)
      end
    when Array
      value.map { |v| deep_transform_keys_to_snake_case(v) }
    else
      value
    end
  end
end
