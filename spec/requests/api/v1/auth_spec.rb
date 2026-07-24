# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "POST /api/v1/auth/signin" do
    context "with valid credentials" do
      it "returns 200 with a JWT token" do
        post "/api/v1/auth/signin",
             params: { auth: { email: "test@example.com", password: "password123" } }.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["attributes"]["token"]).to be_present
        expect(json["data"]["attributes"]["email"]).to eq("test@example.com")
      end

      it "is case-insensitive for email" do
        post "/api/v1/auth/signin",
             params: { auth: { email: "TEST@EXAMPLE.COM", password: "password123" } }.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid credentials" do
      it "returns 401 for wrong password" do
        post "/api/v1/auth/signin",
             params: { auth: { email: "test@example.com", password: "wrong" } }.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Invalid email or password")
      end

      it "returns 401 for unknown email" do
        post "/api/v1/auth/signin",
             params: { auth: { email: "nobody@example.com", password: "password123" } }.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
