require "rails_helper"

RSpec.describe "Api::V1::Conversions", type: :request do
  let!(:user) do
    User.create!(
      google_uid: "google-1",
      email: "user@example.com",
      name: "User Example"
    )
  end

  let(:cookie) { session_cookie_for(user) }

  before do
    allow_any_instance_of(Conversions::SourceTextExtractor).to receive(:call).and_return("01/01/2025 Coffee -3.50")
    allow_any_instance_of(OpenRouter::Client).to receive(:convert_statement_to_rows).and_return(
      {
        "csv_headers" => ["Date", "Description", "Amount"],
        "rows" => [["2025-01-01", "Coffee", -3.5]]
      }
    )
  end

  def uploaded_pdf
    tempfile = Tempfile.new(["statement", ".pdf"])
    tempfile.binmode
    tempfile.write("%PDF-1.4 fake content")
    tempfile.rewind

    Rack::Test::UploadedFile.new(tempfile.path, "application/pdf", original_filename: "statement.pdf")
  end

  def converted_record
    conversion = user.conversions.create!(
      status: :completed,
      original_filename: "statement.pdf",
      content_type: "application/pdf",
      csv_filename: "statement-converted.csv"
    )
    conversion.preview_headers_array = ["Date", "Description", "Amount"]
    conversion.preview_rows_array = [["2025-01-01", "Coffee", -3.5]]
    conversion.save!
    conversion.source_file.attach(
      io: StringIO.new("%PDF-1.4 original"),
      filename: "statement.pdf",
      content_type: "application/pdf"
    )
    conversion.converted_file.attach(
      io: StringIO.new("Date,Description,Amount\n2025-01-01,Coffee,-3.5\n"),
      filename: "statement-converted.csv",
      content_type: "text/csv"
    )
    conversion
  end

  describe "POST /api/v1/conversions" do
    it "creates and converts a statement" do
      post "/api/v1/conversions", params: { file: uploaded_pdf }, headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:created)
      expect(json_response.dig("conversion", "status")).to eq("completed")
      expect(json_response.dig("conversion", "download_url")).to be_present
      expect(json_response.dig("conversion", "json_download_url")).to include("format_type=json")
      expect(json_response.dig("conversion", "source_download_url")).to be_present
    end

    it "rejects non-pdf files" do
      tempfile = Tempfile.new(["statement", ".txt"])
      tempfile.write("plain text")
      tempfile.rewind
      file = Rack::Test::UploadedFile.new(tempfile.path, "text/plain", original_filename: "statement.txt")

      post "/api/v1/conversions", params: { file: file }, headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]).to eq("only_pdf_files_are_allowed")
    end
  end

  describe "GET /api/v1/conversions" do
    it "returns the conversion history" do
      conversion = converted_record

      get "/api/v1/conversions", headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("conversions").first.fetch("id")).to eq(conversion.id)
    end
  end

  describe "GET /api/v1/conversions/:id" do
    it "returns preview headers and rows" do
      conversion = converted_record

      get "/api/v1/conversions/#{conversion.id}", headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("conversion", "preview_headers")).to eq(["Date", "Description", "Amount"])
      expect(json_response.dig("conversion", "preview_rows")).to eq([["2025-01-01", "Coffee", -3.5]])
    end
  end

  describe "PATCH /api/v1/conversions/:id" do
    it "updates preview rows and regenerated exports" do
      conversion = converted_record

      patch "/api/v1/conversions/#{conversion.id}",
        params: {
          preview_headers: ["Date", "Description", "Amount"],
          preview_rows: [["2025-01-02", "Groceries", -25.10]]
        },
        headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("conversion", "preview_rows")).to eq([["2025-01-02", "Groceries", "-25.1"]])
      expect(conversion.reload.converted_file.download).to include("Groceries")
    end
  end

  describe "GET /api/v1/conversions/:id/download" do
    it "downloads the converted csv" do
      conversion = converted_record

      get "/api/v1/conversions/#{conversion.id}/download", headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.body).to include("Date,Description")
    end

    it "downloads the json export" do
      conversion = converted_record

      get "/api/v1/conversions/#{conversion.id}/download", params: { format_type: "json" }, headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("application/json")
      expect(JSON.parse(response.body).fetch("headers")).to eq(["Date", "Description", "Amount"])
    end
  end

  describe "GET /api/v1/conversions/:id/download_source" do
    it "downloads the original pdf" do
      conversion = converted_record

      get "/api/v1/conversions/#{conversion.id}/download_source", headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("application/pdf")
      expect(response.body).to include("%PDF")
    end
  end

  describe "DELETE /api/v1/conversions/:id" do
    it "deletes the conversion and files" do
      conversion = converted_record

      delete "/api/v1/conversions/#{conversion.id}", headers: { "Cookie" => cookie }

      expect(response).to have_http_status(:no_content)
      expect(Conversion.exists?(conversion.id)).to be(false)
    end
  end

  describe "Bearer token auth" do
    it "accepts an api key without a browser session" do
      api_key = user.rotate_api_key!
      conversion = converted_record

      get "/api/v1/conversions/#{conversion.id}", headers: { "Authorization" => "Bearer #{api_key}" }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("conversion", "id")).to eq(conversion.id)
    end
  end
end
