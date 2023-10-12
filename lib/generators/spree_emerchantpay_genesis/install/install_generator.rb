module SpreeEmerchantpayGenesis
  module Generators
    # Emerchantpay plugin install script
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        append_file 'vendor/assets/javascripts/spree/frontend/all.js', "//= require spree/frontend/card.min.js\n"
      end

      def add_stylesheets
        append_file 'vendor/assets/stylesheets/spree/frontend/all.css', "//= require spree/frontend/card.css\n"
      end

      def add_schedule
        # TODO: Add Cron If Needed
        # create_file 'config/schedule.rb' unless File.exist?('config/schedule.rb')
        # append_file 'config/schedule.rb' do
        #   "\nevery '0 4,10,16,22 * * * *' do
        #     rake 'emerchantpay_direct:update_states'
        #   end"
        # end
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_emerchantpay_genesis'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(
          ask('Would you like to run the migrations now? [Y/n]')
        )
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end

    end
  end
end
