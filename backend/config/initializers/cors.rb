Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins = [
      ENV.fetch("FRONTEND_URL", "http://localhost:5173"),
      ENV.fetch("DOCS_URL", "https://docs.statementconverter.ru")
    ].compact

    origins(*origins)

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true,
      expose: %w[Content-Disposition]
  end
end
