require "json"
require "net/http"

module OpenRouter
  class Client
    class Error < StandardError; end

    ENDPOINT = URI("https://openrouter.ai/api/v1/chat/completions")

    def initialize(api_key: ENV["OPENROUTER_API_KEY"], model: ENV.fetch("OPENROUTER_MODEL", "google/gemini-3.1-flash-lite-preview"))
      @api_key = api_key
      @model = model
    end

    def convert_statement_to_rows(statement_text:, original_filename:)
      raise Error, "OPENROUTER_API_KEY is not configured" if api_key.blank?

      request = Net::HTTP::Post.new(ENDPOINT)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload(statement_text:, original_filename:))

      response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true) do |http|
        http.request(request)
      end

      parsed_response = JSON.parse(response.body)
      raise Error, parsed_response.dig("error", "message") || "OpenRouter request failed" unless response.is_a?(Net::HTTPSuccess)

      content = parsed_response.dig("choices", 0, "message", "content")
      raise Error, "OpenRouter returned an empty response" if content.blank?

      JSON.parse(content)
    rescue JSON::ParserError => e
      raise Error, "Failed to parse OpenRouter response: #{e.message}"
    end

    private

    attr_reader :api_key, :model

    def payload(statement_text:, original_filename:)
      {
        model:,
        messages: [
          {
            role: "system",
            content: <<~PROMPT
              You convert raw bank statement text into normalized CSV data.
              Return only valid JSON that matches the provided JSON schema.
              Use English headers only.
              Preserve every transaction row you can confidently identify.
              If a field is missing, use an empty string.
            PROMPT
          },
          {
            role: "user",
            content: <<~PROMPT
              Source filename: #{original_filename}

              Convert the following bank statement content into rows ready for CSV export:

              #{statement_text}
            PROMPT
          }
        ],
        temperature: 0,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "bank_statement_csv",
            strict: true,
            schema: {
              type: "object",
              properties: {
                csv_headers: {
                  type: "array",
                  items: { type: "string" },
                  minItems: 1
                },
                rows: {
                  type: "array",
                  items: {
                    type: "array",
                    items: {
                      anyOf: [
                        { type: "string" },
                        { type: "number" },
                        { type: "integer" }
                      ]
                    }
                  }
                }
              },
              required: %w[csv_headers rows],
              additionalProperties: false
            }
          }
        }
      }
    end
  end
end
