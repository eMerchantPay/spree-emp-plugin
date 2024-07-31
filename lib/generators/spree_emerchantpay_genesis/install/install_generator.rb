require 'rails/generators' # Fix Rails::Generators::Base missing class error in earlier Spree versions

module SpreeEmerchantpayGenesis
  module Generators
    # Emerchantpay plugin install script
    class InstallGenerator < Rails::Generators::Base

      JS_FRONTEND_PATH  = 'vendor/assets/javascripts/spree/frontend/all.js'.freeze
      CSS_FRONTEND_PATH = 'vendor/assets/stylesheets/spree/frontend/all.css'.freeze
      RAKE_PATH         = 'bundle exec rake'.freeze

      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        append_file JS_FRONTEND_PATH, "//= require spree/frontend/card.min.js\n" if File.exist? JS_FRONTEND_PATH
      end

      def add_stylesheets
        append_file CSS_FRONTEND_PATH, "//= require spree/frontend/card.css\n" if File.exist? CSS_FRONTEND_PATH
      end

      def add_migrations
        run "#{RAKE_PATH} railties:install:migrations FROM=spree_emerchantpay_genesis"
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(
          ask('Would you like to run the migrations now? [Y/n]')
        )
        if run_migrations
          run "#{RAKE_PATH} db:migrate"
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end

    end
  end
end
