require "rails_helper"

RSpec.describe "Api::V1::Profiles", type: :request do
  let!(:user) do
    User.create!(
      google_uid: "google-1",
      email: "user@example.com",
      name: "User Example",
      avatar_url: "https://example.com/avatar.png"
    )
  end

  describe "GET /api/v1/me" do
    it "returns unauthorized without a session" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user and code samples" do
      get "/api/v1/me", headers: { "Cookie" => session_cookie_for(user) }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("user", "email")).to eq("user@example.com")
      expect(json_response.dig("user", "api_key")).to start_with("bsc_")
      expect(json_response.dig("code_samples", "curl")).to include("/api/v1/conversions")
      expect(json_response.dig("code_samples", "response_json")).to include("\"conversion\"")
    end
  end

  describe "POST /api/v1/me/api-key" do
    it "rotates and returns a new api key" do
      post "/api/v1/me/api-key", headers: { "Cookie" => session_cookie_for(user) }

      expect(response).to have_http_status(:created)
      expect(json_response["api_key"]).to start_with("bsc_")
      expect(user.reload.api_key_digest).to be_present
    end
  end

  describe "DELETE /api/v1/session" do
    it "logs the user out" do
      delete "/api/v1/session", headers: { "Cookie" => session_cookie_for(user) }

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "DELETE /api/v1/me" do
    it "deletes the current account" do
      delete "/api/v1/me", headers: { "Cookie" => session_cookie_for(user) }

      expect(response).to have_http_status(:no_content)
      expect(User.exists?(user.id)).to be(false)
    end
  end
end
