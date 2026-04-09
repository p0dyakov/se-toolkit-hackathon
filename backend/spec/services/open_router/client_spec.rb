require "rails_helper"

RSpec.describe OpenRouter::Client do
  it "parses a successful structured response" do
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [
            {
              message: {
                content: {
                  csv_headers: ["Date", "Description"],
                  rows: [["2025-01-01", "Salary"]]
                }.to_json
              }
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = described_class.new(api_key: "token", model: "google/gemini-3.1-flash-lite-preview")
    result = client.convert_statement_to_rows(statement_text: "statement", original_filename: "statement.txt")

    expect(result["csv_headers"]).to eq(["Date", "Description"])
    expect(result["rows"]).to eq([["2025-01-01", "Salary"]])
  end
end
