require "rails_helper"

RSpec.describe OauthCallbacksController, type: :controller do
  describe "GET #google" do
    before do
      request.env["omniauth.auth"] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google-1",
        info: {
          email: "user@example.com",
          name: "User Example",
          image: "https://example.com/avatar.png"
        }
      )

      allow(ENV).to receive(:fetch).with("FRONTEND_URL", "http://localhost:5173").and_return("http://localhost:5173")
    end

    it "creates a user session and redirects back to the frontend" do
      get :google

      expect(response).to redirect_to("http://localhost:5173/auth/success")
      expect(session[:user_id]).to eq(User.last.id)
      expect(User.last.email).to eq("user@example.com")
    end
  end
end
