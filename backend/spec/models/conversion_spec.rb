require "rails_helper"

RSpec.describe Conversion, type: :model do
  let(:user) do
    User.create!(google_uid: "google-1", email: "user@example.com", name: "User Example")
  end

  it "defaults to processing status" do
    conversion = described_class.create!(
      user:,
      original_filename: "statement.csv",
      content_type: "text/csv"
    )

    expect(conversion.status).to eq("processing")
  end
end
