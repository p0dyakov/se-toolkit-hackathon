module Api
  module V1
    class ProfilesController < BaseController
      def show
        api_key = current_user.ensure_api_key!

        render json: {
          user: {
            id: current_user.id,
            name: current_user.name,
            email: current_user.email,
            avatar_url: current_user.avatar_url,
            api_key:,
            api_key_configured: current_user.api_key_configured?
          },
          code_samples: code_samples(api_key:)
        }
      end

      def rotate_api_key
        api_key = current_user.rotate_api_key!

        render json: {
          api_key:,
          code_samples: code_samples(api_key:)
        }, status: :created
      end

      def destroy
        current_user.destroy!
        reset_session

        head :no_content
      end

      def code_samples(api_key: "YOUR_API_KEY")
        base_url = request.base_url
        curl = <<~CURL.strip
          curl -X POST #{base_url}/api/v1/conversions \\
            -H "Authorization: Bearer #{api_key}" \\
            -F "file=@statement.pdf"
        CURL
        ruby = <<~RUBY.strip
          require "net/http"
          require "json"

          uri = URI("#{base_url}/api/v1/conversions")
          request = Net::HTTP::Post.new(uri)
          request["Authorization"] = "Bearer #{api_key}"
          request.set_form([["file", File.open("statement.pdf")]], "multipart/form-data")

          response = Net::HTTP.start(uri.host, uri.port) do |http|
            http.request(request)
          end

          puts response.body
        RUBY
        python = <<~PYTHON.strip
          import requests

          response = requests.post(
            "#{base_url}/api/v1/conversions",
            headers={"Authorization": "Bearer #{api_key}"},
            files={"file": ("statement.pdf", open("statement.pdf", "rb"), "application/pdf")},
          )
          print(response.json())
        PYTHON
        typescript = <<~TYPESCRIPT.strip
          const formData = new FormData();
          formData.append("file", file);

          const response = await fetch("#{base_url}/api/v1/conversions", {
            method: "POST",
            headers: {
              Authorization: "Bearer #{api_key}",
            },
            body: formData,
          });

          const payload: {
            conversion: {
              id: number;
              status: "processing" | "completed" | "failed";
              original_filename: string;
              download_url: string | null;
              json_download_url: string | null;
              source_download_url: string | null;
            };
          } = await response.json();

          console.log(payload);
        TYPESCRIPT
        javascript = <<~JAVASCRIPT.strip
          const formData = new FormData();
          formData.append("file", fileInput.files[0]);

          const response = await fetch("#{base_url}/api/v1/conversions", {
            method: "POST",
            headers: { Authorization: "Bearer #{api_key}" },
            body: formData,
          });

          console.log(await response.json());
        JAVASCRIPT
        go = <<~GO.strip
          package main

          import (
            "bytes"
            "fmt"
            "io"
            "mime/multipart"
            "net/http"
            "os"
          )

          func main() {
            file, _ := os.Open("statement.pdf")
            defer file.Close()

            var body bytes.Buffer
            writer := multipart.NewWriter(&body)
            part, _ := writer.CreateFormFile("file", "statement.pdf")
            io.Copy(part, file)
            writer.Close()

            req, _ := http.NewRequest("POST", "#{base_url}/api/v1/conversions", &body)
            req.Header.Set("Authorization", "Bearer #{api_key}")
            req.Header.Set("Content-Type", writer.FormDataContentType())

            res, _ := http.DefaultClient.Do(req)
            defer res.Body.Close()

            payload, _ := io.ReadAll(res.Body)
            fmt.Println(string(payload))
          }
        GO
        php = <<~PHP.strip
          <?php

          $ch = curl_init("#{base_url}/api/v1/conversions");
          curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Authorization: Bearer #{api_key}",
          ]);
          curl_setopt($ch, CURLOPT_POST, true);
          curl_setopt($ch, CURLOPT_POSTFIELDS, [
            "file" => new CURLFile("statement.pdf", "application/pdf", "statement.pdf"),
          ]);
          curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

          $response = curl_exec($ch);
          curl_close($ch);

          echo $response;
        PHP
        response_json = <<~JSON.strip
          {
            "conversion": {
              "id": 42,
              "status": "completed",
              "original_filename": "statement.pdf",
              "content_type": "application/pdf",
              "error_message": null,
              "csv_filename": "statement-42.csv",
              "created_at": "2026-04-09T10:30:00Z",
              "updated_at": "2026-04-09T10:30:04Z",
              "download_url": "/api/v1/conversions/42/downloads/csv",
              "json_download_url": "/api/v1/conversions/42/downloads/json",
              "source_download_url": "/api/v1/conversions/42/downloads/source"
            }
          }
        JSON

        {
          curl:,
          ruby:,
          python:,
          typescript:,
          javascript:,
          go:,
          php:,
          response_json:
        }
      end
    end
  end
end
