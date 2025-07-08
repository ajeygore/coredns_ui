# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_CLIENT_ID', nil), ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
           scope: 'email, profile'
end
OmniAuth.config.allowed_request_methods = %i[get]

# need to add this to .env file for google oauth in production environment
OmniAuth.config.full_host = Rails.env.production? ? ENV.fetch('APP_PUBLIC_FQDN') : 'http://localhost:3000'
