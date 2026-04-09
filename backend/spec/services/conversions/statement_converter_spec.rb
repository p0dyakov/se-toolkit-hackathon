require "rails_helper"

RSpec.describe Conversions::StatementConverter do
  let(:user) do
    User.create!(google_uid: "google-1", email: "user@example.com", name: "User Example")
  end

  let(:conversion) do
    user.conversions.create!(
      original_filename: "statement.pdf",
      content_type: "application/pdf"
    )
  end

  before do
    conversion.source_file.attach(
      io: StringIO.new("%PDF-1.4 fake pdf"),
      filename: "statement.pdf",
      content_type: "application/pdf"
    )
    allow_any_instance_of(Conversions::SourceTextExtractor).to receive(:call).and_return("01/01/2025 Grocery Store -54.25 USD")
  end

  it "creates and attaches a converted csv file" do
    client = instance_double(
      OpenRouter::Client,
      convert_statement_to_rows: {
        "csv_headers" => ["Date", "Description", "Amount", "Currency"],
        "rows" => [["2025-01-01", "Grocery Store", -54.25, "USD"]]
      }
    )

    described_class.new(conversion:, client:).call

    conversion.reload
    expect(conversion).to be_completed
    expect(conversion.csv_filename).to eq("statement-converted.csv")
    expect(conversion.converted_file).to be_attached
    expect(conversion.converted_file.download).to include("Date,Description,Amount,Currency")
  end

  it "marks the conversion as failed when the AI client raises" do
    client = instance_double(OpenRouter::Client)
    allow(client).to receive(:convert_statement_to_rows).and_raise(OpenRouter::Client::Error, "upstream failure")

    expect do
      described_class.new(conversion:, client:).call
    end.to raise_error(described_class::ConversionError, "upstream failure")

    conversion.reload
    expect(conversion).to be_failed
    expect(conversion.error_message).to eq("upstream failure")
  end
end
