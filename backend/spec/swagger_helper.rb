# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("openapi").to_s
  config.openapi_format = :json

  config.openapi_specs = {
    "v1/openapi.json" => {
      openapi: "3.0.1",
      info: {
        title: "Bank Statement Converter API",
        version: "v1",
        description: "API for Google authentication, profile management, bank statement conversion, and CSV downloads."
      },
      servers: [
        {
          url: "http://localhost:3000"
        }
      ],
      paths: {},
      components: {
        securitySchemes: {
          sessionCookie: {
            type: :apiKey,
            in: :cookie,
            name: "_bank_statement_converter_session"
          }
        },
        schemas: {
          user: {
            type: :object,
            required: %w[id name email avatar_url],
            properties: {
              id: { type: :integer },
              name: { type: :string },
              email: { type: :string, format: :email },
              avatar_url: { type: %i[string null] }
            }
          },
          conversion: {
            type: :object,
            required: %w[id status original_filename content_type error_message csv_filename created_at updated_at download_url],
            properties: {
              id: { type: :integer },
              status: { type: :string, enum: %w[processing completed failed] },
              original_filename: { type: :string },
              content_type: { type: :string },
              error_message: { type: %i[string null] },
              csv_filename: { type: %i[string null] },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" },
              download_url: { type: %i[string null] }
            }
          }
        }
      }
    }
  }
end
