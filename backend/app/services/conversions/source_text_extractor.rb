require "csv"
require "digest"
require "stringio"

module Conversions
  class SourceTextExtractor
    class ExtractionError < StandardError; end

    def initialize(conversion:)
      @conversion = conversion
    end

    def call
      raise ExtractionError, "Source file is missing" unless conversion.source_file.attached?

      content = conversion.source_file.download
      conversion.update!(source_checksum: Digest::SHA256.hexdigest(content))

      case normalized_content_type
      when "application/pdf"
        extract_pdf(content)
      else
        raise ExtractionError, "Unsupported file type: #{conversion.content_type}"
      end
    end

    private

    attr_reader :conversion

    def normalized_content_type
      conversion.content_type
    end

    def extract_pdf(content)
      PDF::Reader.new(StringIO.new(content)).pages.map(&:text).join("\n")
    rescue PDF::Reader::MalformedPDFError, ArgumentError => e
      raise ExtractionError, "Unable to read PDF: #{e.message}"
    end

  end
end
