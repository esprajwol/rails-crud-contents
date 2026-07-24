# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users/signup" do
    let(:valid_params) do
      {
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        password: "password123",
        country: "USA"
      }
    end

    context "with valid params" do
      it "creates a user and returns 201 with JWT token" do
        expect {
          post "/api/v1/users/signup",
               params: valid_params.to_json,
               headers: { "Content-Type" => "application/json" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["type"]).to eq("users")
        expect(json["data"]["attributes"]["token"]).to be_present
        expect(json["data"]["attributes"]["email"]).to eq("john@example.com")
        expect(json["data"]["attributes"]["name"]).to eq("John Doe")
        expect(json["data"]["attributes"]["country"]).to eq("USA")
        expect(json["data"]["attributes"]["createdAt"]).to be_present
      end

      it "normalizes email to lowercase" do
        post "/api/v1/users/signup",
             params: valid_params.merge(email: "JOHN@EXAMPLE.COM").to_json,
             headers: { "Content-Type" => "application/json" }
        json = JSON.parse(response.body)
        expect(json["data"]["attributes"]["email"]).to eq("john@example.com")
      end

      it "works without the optional country field" do
        post "/api/v1/users/signup",
             params: valid_params.except(:country).to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      it "returns 422 when email is already taken" do
        create(:user, email: "john@example.com")
        post "/api/v1/users/signup",
             params: valid_params.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_an(Array)
      end

      it "returns 422 when password is too short" do
        post "/api/v1/users/signup",
             params: valid_params.merge(password: "abc").to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"].any? { |e| e.include?("Password") }).to be_truthy
      end

      it "returns 422 when email format is invalid" do
        post "/api/v1/users/signup",
             params: valid_params.merge(email: "not-an-email").to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_an(Array)
      end
    end
  end
end
