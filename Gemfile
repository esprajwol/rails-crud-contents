source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.0"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4"

# JWT for authentication
gem "jwt", "~> 2.7"

# bcrypt for has_secure_password
gem "bcrypt", "~> 3.1.7"

# Rack CORS for handling Cross-Origin Resource Sharing (CORS)
gem "rack-cors"

# Redis — used as Rails.cache store for user-lookup caching in auth
gem "redis", "~> 5.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Environment variables
gem "dotenv-rails"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem "database_cleaner-active_record"
end
