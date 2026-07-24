# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Contents", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:token)      { JsonWebToken.encode(user_id: user.id) }
  let(:other_token){ JsonWebToken.encode(user_id: other_user.id) }
  let(:auth_headers)       { { "Authorization" => "Bearer #{token}" } }
  let(:other_auth_headers) { { "Authorization" => "Bearer #{other_token}" } }

  describe "GET /api/v1/contents" do
    context "with a valid token" do
      it "returns a list of all contents" do
        create_list(:content, 3, user: user)
        get "/api/v1/contents", headers: auth_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(3)
      end

      it "returns empty array when no contents exist" do
        get "/api/v1/contents", headers: auth_headers
        json = JSON.parse(response.body)
        expect(json["data"]).to eq([])
      end
    end

    context "without a token" do
      it "returns 401 Unauthorized" do
        get "/api/v1/contents"
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Unauthorized")
      end
    end

    context "with alias route /api/v1/content" do
      it "also returns contents list" do
        create(:content, user: user)
        get "/api/v1/content", headers: auth_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
      end
    end
  end

  describe "GET /api/v1/contents/:id" do
    let(:content) { create(:content, user: user) }

    context "with a valid token" do
      it "returns the content" do
        get "/api/v1/contents/#{content.id}", headers: auth_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["id"]).to eq(content.id)
        expect(json["data"]["type"]).to eq("content")
        expect(json["data"]["attributes"]["title"]).to eq(content.title)
      end

      it "returns 404 for a non-existent content" do
        get "/api/v1/contents/99999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end

    context "without a token" do
      it "returns 401 Unauthorized" do
        get "/api/v1/contents/#{content.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/contents" do
    let(:valid_params) { { title: "Test Content", body: "This is the body." } }

    context "with a valid token and valid params" do
      it "creates a content and returns 201" do
        expect {
          post "/api/v1/contents",
               params: valid_params.to_json,
               headers: auth_headers.merge("Content-Type" => "application/json")
        }.to change(Content, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["attributes"]["title"]).to eq("Test Content")
        # Verify user_id is not exposed in attributes
        expect(json["data"]["attributes"].key?("userId")).to be_falsey
      end

      it "creates content with camelCase input keys" do
        post "/api/v1/contents",
             params: { title: "CamelCase Test", body: "Body here" }.to_json,
             headers: auth_headers.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:created)
      end
    end

    context "with missing required fields" do
      it "returns 422 with error messages" do
        post "/api/v1/contents",
             params: { title: "" }.to_json,
             headers: auth_headers.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_an(Array)
        expect(json["errors"]).not_to be_empty
      end
    end

    context "without a token" do
      it "returns 401 Unauthorized" do
        post "/api/v1/contents",
             params: valid_params.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/v1/contents/:id" do
    let(:content) { create(:content, user: user) }
    let(:update_params) { { title: "Updated Title", body: "Updated body." } }

    context "as the owner" do
      it "updates the content and returns 200" do
        put "/api/v1/contents/#{content.id}",
            params: update_params.to_json,
            headers: auth_headers.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["attributes"]["title"]).to eq("Updated Title")
      end

      it "returns 422 when update params are invalid" do
        put "/api/v1/contents/#{content.id}",
            params: { title: "", body: "" }.to_json,
            headers: auth_headers.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_an(Array)
      end
    end

    context "as a different user (non-owner)" do
      it "returns 403 Forbidden" do
        put "/api/v1/contents/#{content.id}",
            params: update_params.to_json,
            headers: other_auth_headers.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("You are not authorized to modify this content")
      end
    end

    context "without a token" do
      it "returns 401 Unauthorized" do
        put "/api/v1/contents/#{content.id}",
            params: update_params.to_json,
            headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when content does not exist" do
      it "returns 404" do
        put "/api/v1/contents/99999",
            params: update_params.to_json,
            headers: auth_headers.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/contents/:id" do
    let!(:content) { create(:content, user: user) }

    context "as the owner" do
      it "deletes the content and returns 200 with message" do
        expect {
          delete "/api/v1/contents/#{content.id}", headers: auth_headers
        }.to change(Content, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Deleted")
      end
    end

    context "as a different user (non-owner)" do
      it "returns 403 Forbidden" do
        expect {
          delete "/api/v1/contents/#{content.id}", headers: other_auth_headers
        }.not_to change(Content, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("You are not authorized to modify this content")
      end
    end

    context "without a token" do
      it "returns 401 Unauthorized" do
        delete "/api/v1/contents/#{content.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when content does not exist" do
      it "returns 404" do
        delete "/api/v1/contents/99999", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "Response shape" do
    it "returns camelCase keys in single resource responses" do
      content = create(:content, user: user)
      get "/api/v1/contents/#{content.id}", headers: auth_headers
      json = JSON.parse(response.body)
      attrs = json["data"]["attributes"]
      # createdAt and updatedAt should be camelCase
      expect(attrs.key?("createdAt")).to be_truthy
      expect(attrs.key?("updatedAt")).to be_truthy
      # snake_case should NOT be present
      expect(attrs.key?("created_at")).to be_falsey
    end
  end
end
