require 'fileutils'
require 'generators/spree_emerchantpay_genesis/install/install_generator'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe SpreeEmerchantpayGenesis::Generators::InstallGenerator do
  let(:js_path) { "spec/dummy/#{described_class::JS_FRONTEND_PATH}" }
  let(:css_path) { "spec/dummy/#{described_class::CSS_FRONTEND_PATH}" }
  let(:generator) do
    described_class.new
  end
  let(:create_js_config!) do
    dir = File.dirname(js_path)

    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    File.new(js_path, 'w')
  end
  let(:create_css_config!) do
    dir = File.dirname(css_path)

    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    File.new(css_path, 'w')
  end
  let(:reset_migrations!) do
    FileUtils.rm_rf Dir.glob(File.join('spec/dummy', 'db/**/*spree_emerchantpay_genesis.rb'))
  end
  let(:drop_engine_tables!) do
    connection_configs = YAML.safe_load(File.read('spec/dummy/config/database.yml'), aliases: true)
    ActiveRecord::Base.establish_connection(connection_configs['test'])
    ActiveRecord::Base.connection.execute 'DROP TABLE emerchantpay_payments;'
  end

  before do
    stub_const(
      'SpreeEmerchantpayGenesis::Generators::InstallGenerator::RAKE_PATH',
      'RAILS_ENV=test bin/rake'
    )
    allow(generator).to receive_messages options: { auto_run_migrations: true }
  end

  after do
    FileUtils.rm_rf %w(spec/dummy/vendor/assets/javascripts/spree/frontend
      spec/dummy/vendor/assets/stylesheets/spree/frontend)
  end

  describe 'when frontend' do
    before do
      stub_const('SpreeEmerchantpayGenesis::Generators::InstallGenerator::JS_FRONTEND_PATH', js_path)
      stub_const('SpreeEmerchantpayGenesis::Generators::InstallGenerator::CSS_FRONTEND_PATH', css_path)
    end

    describe 'without frontend' do
      it 'without error for javascripts' do
        expect { generator.add_javascripts }.to_not raise_error
      end

      it 'without erorr for stylesheets' do
        expect { generator.add_stylesheets }.to_not raise_error
      end
    end

    describe 'with frontend' do
      before do
        create_js_config!
        create_css_config!
      end

      it 'when add frontend javascript' do
        generator.add_javascripts

        expect(File.read(js_path)).to eq "//= require spree/frontend/card.min.js\n"
      end

      it 'when add frontend stylesheets' do
        generator.add_stylesheets

        expect(File.read(css_path)).to eq "//= require spree/frontend/card.css\n"
      end
    end
  end

  it 'when add_migrations' do
    reset_migrations!

    Dir.chdir('spec/dummy') { generator.add_migrations }

    expect(Dir.glob(File.join('spec/dummy', 'db/**/*spree_emerchantpay_genesis.rb')).count).to eq 2
  end

  it 'when run_migrations' do # rubocop:disable RSpec/ExampleLength
    # Reset migrations, SchemaMigrations is not truncated
    reset_migrations!
    drop_engine_tables!

    Dir.chdir('spec/dummy') do
      generator.add_migrations
      generator.run_migrations
    end

    expect(ActiveRecord::Base.connection.tables).to include 'emerchantpay_payments'
  end

  it 'when ask' do
    allow(generator).to receive_messages ask: 'n'
    allow(generator).to receive_messages options: { auto_run_migrations: false }

    expect { generator.run_migrations }
      .to output("Skipping rake db:migrate, don't forget to run it!\n").to_stdout
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
