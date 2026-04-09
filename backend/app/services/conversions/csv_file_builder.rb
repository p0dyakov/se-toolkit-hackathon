require "csv"

module Conversions
  class CsvFileBuilder
    def initialize(headers:, rows:)
      @headers = headers
      @rows = rows
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << headers

        rows.each do |row|
          csv << normalized_row(row)
        end
      end
    end

    private

    attr_reader :headers, :rows

    def normalized_row(row)
      normalized = Array(row).map { |value| value.is_a?(String) ? value.strip : value }
      normalized.fill("", normalized.length...headers.length)
      normalized.take(headers.length)
    end
  end
end
