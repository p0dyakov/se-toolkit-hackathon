require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes email before validation" do
    user = described_class.create!(
      google_uid: "google-123",
      email: " USER@Example.COM ",
      name: "Jane Doe"
    )

    expect(user.email).to eq("user@example.com")
  end

  it "auto-generates an api key token and digest" do
    user = described_class.create!(
      google_uid: "google-456",
      email: "api@example.com",
      name: "API User"
    )

    expect(user.api_key_token).to start_with("bsc_")
    expect(user.api_key_digest).to eq(described_class.digest_api_key(user.api_key_token))
  end
end
