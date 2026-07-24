require_relative "boot"

require "rails"
# API-only: only load the required frameworks
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AngelswingApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `node_modules`.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller subset of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Auto-load lib directory
    config.autoload_paths << Rails.root.join("lib")

    # Redis cache store — used for user-identity caching in JWT auth.
    # Falls back to :memory_store when REDIS_URL is not set (e.g. in CI/test).
    redis_url = ENV.fetch("REDIS_URL", nil)
    if redis_url
      config.cache_store = :redis_cache_store, {
        url:              redis_url,
        expires_in:       1.hour,           # default TTL for cached entries
        connect_timeout:  0.5,              # fail fast if Redis is unreachable
        read_timeout:     0.5,
        write_timeout:    0.5,
        error_handler: ->(method:, returning:, exception:) {
          Rails.logger.error "RedisCache error on #{method}: #{exception.message}"
        }
      }
    else
      config.cache_store = :memory_store, { size: 32.megabytes }
    end
  end
end
