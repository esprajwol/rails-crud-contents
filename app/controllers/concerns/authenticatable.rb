# frozen_string_literal: true

# Include this concern in controllers that require JWT authentication.
# Sets current_user from the bearer token in Authorization header,
# or renders 401 Unauthorized.
#
# Performance: resolved users are cached in Redis (via Rails.cache) to avoid
# a DB hit on every authenticated request. Cache key: "user_auth:<user_id>".
# TTL defaults to 1 hour (configured in config/application.rb).
# The cache is bypassed gracefully if Redis is unavailable.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
    token = extract_token_from_header
    if token.nil?
      return render_json({ error: "Unauthorized" }, status: :unauthorized)
    end

    decoded = JsonWebToken.decode(token)
    if decoded.nil?
      return render_json({ error: "Unauthorized" }, status: :unauthorized)
    end

    @current_user = fetch_user_from_cache(decoded[:user_id])
    unless @current_user
      render_json({ error: "Unauthorized" }, status: :unauthorized)
    end
  end

  def current_user
    @current_user
  end

  private

  # Fetches the user from Redis cache; falls back to DB on a cache miss.
  #
  # Cache key:  "user_auth:<user_id>"
  # TTL:        1 hour (set globally on the cache store)
  #
  # If Redis is down, Rails.cache silently falls through to the DB so the
  # API stays available — Redis failure is logged but never raises.
  def fetch_user_from_cache(user_id)
    Rails.cache.fetch(user_cache_key(user_id)) do
      # Block only runs on a cache miss (DB query)
      User.find_by(id: user_id)
    end
  end

  # Deterministic, namespaced cache key per user.
  def user_cache_key(user_id)
    "user_auth:#{user_id}"
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil if auth_header.blank?

    parts = auth_header.split(" ")
    return nil unless parts.length == 2 && parts[0].downcase == "bearer"

    parts[1]
  end
end
