module Api
  module V1
    class ConversionsController < BaseController
      MAX_FILE_SIZE = 15.megabytes
      PDF_CONTENT_TYPES = ["application/pdf"].freeze

      def index
        render json: {
          conversions: current_user.conversions.order(created_at: :desc).map { |conversion| serialize_conversion(conversion) }
        }
      end

      def show
        conversion = current_user.conversions.find(params[:id])
        render json: {
          conversion: serialize_conversion(conversion).merge(
            preview_headers: conversion.preview_headers_array,
            preview_rows: conversion.preview_rows_array
          )
        }
      end

      def create
        uploaded_file = params[:file]

        if uploaded_file.blank?
          render json: { error: "file_is_required" }, status: :unprocessable_entity
          return
        end

        validation_error = validate_upload(uploaded_file)
        if validation_error
          render json: { error: validation_error }, status: :unprocessable_entity
          return
        end

        conversion = current_user.conversions.create!(
          original_filename: uploaded_file.original_filename,
          content_type: uploaded_file.content_type.presence || "application/octet-stream",
          status: :processing
        )
        conversion.source_file.attach(uploaded_file)

        Conversions::StatementConverter.new(conversion:).call
        conversion.reload

        render json: { conversion: serialize_conversion(conversion) }, status: :created
      rescue Conversions::StatementConverter::ConversionError => e
        conversion&.reload
        render json: { conversion: serialize_conversion(conversion), error: e.message }, status: :unprocessable_entity
      end

      def update
        conversion = current_user.conversions.find(params[:id])
        headers = Array(params[:preview_headers]).map(&:to_s)
        rows = normalize_preview_rows(params[:preview_rows])

        if headers.empty?
          render json: { error: "preview_headers_are_required" }, status: :unprocessable_entity
          return
        end

        csv_body = Conversions::CsvFileBuilder.new(headers:, rows:).call
        json_body = JSON.pretty_generate(headers: headers, rows: rows)

        conversion.preview_headers_array = headers
        conversion.preview_rows_array = rows
        conversion.csv_filename ||= generated_csv_filename(conversion)
        conversion.converted_file.attach(
          io: StringIO.new(csv_body),
          filename: conversion.csv_filename,
          content_type: "text/csv"
        )
        conversion.update!(status: :completed, error_message: nil)
        attach_json_export(conversion, json_body)

        render json: {
          conversion: serialize_conversion(conversion).merge(
            preview_headers: conversion.preview_headers_array,
            preview_rows: conversion.preview_rows_array
          )
        }
      end

      def download
        conversion = current_user.conversions.find(params[:id])

        if params[:format_type] == "json" || params[:format] == "json"
          download_json_export(conversion)
          return
        end

        unless conversion.completed? && conversion.converted_file.attached?
          render json: { error: "converted_file_not_available" }, status: :unprocessable_entity
          return
        end

        send_data conversion.converted_file.download,
          filename: conversion.csv_filename.presence || "converted.csv",
          disposition: :attachment,
          type: "text/csv"
      end

      def download_source
        conversion = current_user.conversions.find(params[:id])

        unless conversion.source_file.attached?
          render json: { error: "source_file_not_available" }, status: :unprocessable_entity
          return
        end

        send_data conversion.source_file.download,
          filename: conversion.original_filename,
          disposition: :attachment,
          type: conversion.content_type
      end

      def destroy
        conversion = current_user.conversions.find(params[:id])
        conversion.source_file.purge if conversion.source_file.attached?
        conversion.converted_file.purge if conversion.converted_file.attached?
        conversion.destroy!

        head :no_content
      end

      private

      def serialize_conversion(conversion)
        {
          id: conversion.id,
          status: conversion.status,
          original_filename: conversion.original_filename,
          content_type: conversion.content_type,
          error_message: conversion.error_message,
          csv_filename: conversion.csv_filename,
          created_at: conversion.created_at,
          updated_at: conversion.updated_at,
          download_url: conversion.completed? && conversion.converted_file.attached? ? download_api_v1_conversion_path(conversion) : nil,
          json_download_url: conversion.completed? ? download_api_v1_conversion_path(conversion, format_type: "json") : nil,
          source_download_url: conversion.source_file.attached? ? download_source_api_v1_conversion_path(conversion) : nil
        }
      end

      def validate_upload(uploaded_file)
        return "only_pdf_files_are_allowed" unless PDF_CONTENT_TYPES.include?(uploaded_file.content_type)
        return "file_too_large_maximum_15_mb" if uploaded_file.size.to_i > MAX_FILE_SIZE

        nil
      end

      def generated_csv_filename(conversion)
        "#{File.basename(conversion.original_filename, ".*").parameterize.presence || "statement"}-converted.csv"
      end

      def generated_json_filename(conversion)
        "#{File.basename(conversion.original_filename, ".*").parameterize.presence || "statement"}-converted.json"
      end

      def json_export_path(conversion)
        Rails.root.join("tmp", "storage", "conversion-json-#{conversion.id}.json")
      end

      def attach_json_export(conversion, json_body)
        File.write(json_export_path(conversion), json_body)
      end

      def download_json_export(conversion)
        unless conversion.completed?
          render json: { error: "json_export_not_available" }, status: :unprocessable_entity
          return
        end

        send_data JSON.pretty_generate(
          headers: conversion.preview_headers_array,
          rows: conversion.preview_rows_array
        ),
          filename: generated_json_filename(conversion),
          disposition: :attachment,
          type: "application/json"
      end

      def normalize_preview_rows(raw_rows)
        rows = Array(raw_rows)
        return [] if rows.empty?
        return rows if rows.all? { |row| row.is_a?(Array) }

        [rows]
      end
    end
  end
end
