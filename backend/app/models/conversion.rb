class Conversion < ApplicationRecord
  belongs_to :user

  has_one_attached :source_file
  has_one_attached :converted_file

  enum :status, {
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, validate: true

  validates :original_filename, presence: true
  validates :content_type, presence: true
  validates :status, presence: true

  def preview_headers_array
    JSON.parse(preview_headers || "[]")
  end

  def preview_rows_array
    JSON.parse(preview_rows || "[]")
  end

  def preview_headers_array=(headers)
    self.preview_headers = Array(headers).to_json
  end

  def preview_rows_array=(rows)
    self.preview_rows = Array(rows).to_json
  end
end
