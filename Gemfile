source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.0"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 1.4"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  gem "rspec-rails"

  # gem "ruby-debug-ide"

  # platform :jruby do
  #   gem "ruby-debug-base"
  # end

  # platform :ruby do
  #   gem "debase"
  # end
end

group :test do
  gem "shoulda-matchers"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "erb-formatter"
  gem "guard", require: false
  gem "guard-rubocop", require: false
  gem "rubocop", require: false
  gem "ruby-lsp"
  gem "web-console"
  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem "spring"

  gem "rubocop-discourse"
  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  # gem "rubocop-rails-omakase", require: false
  # Sensible style https://github.com/okuramasafumi/rubocop-sensible
  gem 'rubocop-sensible', group: :development, require: false
end

# Please note Sorbet required watchman, install in your system
# after that rung
# bundle exec srb typecheck --lsp
# More about this is here https://sorbet.org/docs/adopting
#  gem "tapioca", require: false, :group => [:development, :test]
#  bundle exec tapioca init
gem "sorbet-static-and-runtime"
gem "tapioca", require: false, group: %i[development test]
gem "watchman", require: false, group: %i[development test]
gem "foreman", require: false, group: %i[development test]

gem "slim-rails"

gem "dotenv-rails"
gem "omniauth-google-oauth2"

gem "pry", "~> 0.14.2"

gem "httparty", "~> 0.22.0"
