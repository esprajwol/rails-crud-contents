# frozen_string_literal: true

require "jwt"

# Service object that wraps JWT encode/decode logic.
# Reads the secret from ENV["JWT_SECRET"] with a dev-only fallback.
module JsonWebToken
  SECRET_KEY = ENV.fetch("JWT_SECRET", "dev_only_fallback_secret_change_in_production")
  ALGORITHM  = "HS256"
  DEFAULT_EXP = 24 * 60 * 60 # 24 hours in seconds

  # Encodes a payload into a signed JWT.
  #
  # @param payload [Hash] the claims to encode (e.g. { user_id: 1 })
  # @param exp [Integer] expiry in seconds from now (default: 24h)
  # @return [String] the encoded JWT
  def self.encode(payload, exp: DEFAULT_EXP)
    payload = payload.merge(exp: Time.now.to_i + exp)
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  # Decodes and verifies a JWT string.
  #
  # @param token [String] the JWT to decode
  # @return [HashWithIndifferentAccess, nil] decoded payload, or nil on failure
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: ALGORITHM)
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError
    nil
  end
end
