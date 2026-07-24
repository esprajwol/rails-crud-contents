# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# No seed data required for this application.
# The API provides signup/signin endpoints to create and authenticate users.

puts "No seed data needed — use POST /api/v1/users/signup to create users."
