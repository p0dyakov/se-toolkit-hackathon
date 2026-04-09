class ApiDocsController < ActionController::Base
  def show
    render inline: <<~HTML
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>Bank Statement Converter API</title>
          <style>
            body {
              margin: 0;
              background: #f8f7f2;
              font-family: "Iowan Old Style", "Palatino Linotype", serif;
            }
          </style>
        </head>
        <body>
          <div id="app"></div>
          <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
          <script>
            Scalar.createApiReference('#app', {
              url: '/openapi/v1/openapi.json',
              theme: 'default',
              layout: 'modern',
            })
          </script>
        </body>
      </html>
    HTML
  end
end
