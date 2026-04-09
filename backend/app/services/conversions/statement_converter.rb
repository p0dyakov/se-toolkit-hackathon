module Conversions
  class StatementConverter
    class ConversionError < StandardError; end

    def initialize(conversion:, client: OpenRouter::Client.new)
      @conversion = conversion
      @client = client
    end

    def call
      extracted_text = SourceTextExtractor.new(conversion:).call
      raise ConversionError, "The uploaded statement did not contain readable text" if extracted_text.blank?

      ai_result = client.convert_statement_to_rows(
        statement_text: extracted_text,
        original_filename: conversion.original_filename
      )

      headers = Array(ai_result["csv_headers"]).map(&:to_s)
      rows = Array(ai_result["rows"])
      raise ConversionError, "The AI response did not include CSV headers" if headers.empty?

      csv_body = CsvFileBuilder.new(headers:, rows:).call
      conversion.converted_file.attach(
        io: StringIO.new(csv_body),
        filename: generated_filename,
        content_type: "text/csv"
      )

      conversion.preview_headers_array = headers
      conversion.preview_rows_array = rows
      conversion.update!(
        status: :completed,
        csv_filename: generated_filename,
        error_message: nil
      )
    rescue OpenRouter::Client::Error, SourceTextExtractor::ExtractionError => e
      fail_conversion!(e.message)
    rescue StandardError => e
      fail_conversion!("Conversion failed: #{e.message}")
    end

    private

    attr_reader :conversion, :client

    def generated_filename
      base = File.basename(conversion.original_filename, ".*").parameterize.presence || "statement"
      "#{base}-converted.csv"
    end

    def fail_conversion!(message)
      conversion.update!(status: :failed, error_message: message)
      raise ConversionError, message
    end
  end
end
