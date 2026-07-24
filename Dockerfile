# syntax=docker/dockerfile:1

# ─── Build stage ────────────────────────────────────────────────────────────
FROM ruby:3.3.6-slim AS build

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Install gems first (better layer caching)
COPY Gemfile Gemfile.lock* ./
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# ─── Final stage ─────────────────────────────────────────────────────────────
FROM ruby:3.3.6-slim AS final

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      postgresql-client \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Copy gems from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle

# Copy app from build stage
COPY --from=build /rails /rails

# Make entrypoint executable (in case git lost permissions)
RUN chmod +x /rails/bin/docker-entrypoint.sh

# Create a non-root user for security
RUN useradd -m -s /bin/bash rails && \
    chown -R rails:rails /rails /usr/local/bundle

USER rails

# Expose port
EXPOSE 3000

# Entrypoint: run migrations then start server
ENTRYPOINT ["/rails/bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
