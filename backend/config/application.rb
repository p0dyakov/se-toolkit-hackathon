require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module Backend
  class Application < Rails::Application
    config.load_defaults 7.2

    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true

    config.generators do |generator|
      generator.test_framework :rspec
    end

    config.session_store :cookie_store,
      key: "_bank_statement_converter_session",
      same_site: :lax,
      secure: Rails.env.production?,
      httponly: true,
      domain: ENV["SESSION_COOKIE_DOMAIN"].presence

    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options
  end
end
